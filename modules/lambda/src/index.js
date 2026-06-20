const https = require('https');
const http = require('http');
const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');
const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');

const sns = new SNSClient({ region: process.env.AWS_REGION || 'us-east-1' });
const secretsClient = new SecretsManagerClient({ region: process.env.AWS_REGION || 'us-east-1' });

const VEHICLE_SERVICE_URL     = process.env.VEHICLE_SERVICE_URL    || '';
const AUTH_SERVICE_URL        = process.env.AUTH_SERVICE_URL       || '';
const CREDENTIALS_SECRET_ARN  = process.env.LAMBDA_SERVICE_CREDENTIALS_SECRET_ARN || '';
const INSURANCE_SNS_ARN       = process.env.INSURANCE_SNS_ARN     || '';
const SERVICE_SNS_ARN         = process.env.SERVICE_SNS_ARN       || '';

// Module-level JWT cache — persists across warm invocations
let cachedToken = null;
let tokenExpiresAt = 0;

// ── HTTP helpers ──────────────────────────────────────────────────────────────

function httpRequest(url, options = {}, body = null) {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith('https') ? https : http;
    const req = lib.request(url, options, (res) => {
      let data = '';
      res.on('data', chunk => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode >= 400) {
          reject(new Error(`HTTP ${res.statusCode} from ${url}: ${data.substring(0, 200)}`));
          return;
        }
        try { resolve(JSON.parse(data)); }
        catch (e) { reject(new Error(`Invalid JSON from ${url}: ${data.substring(0, 200)}`)); }
      });
    });
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

function fetchJson(url, token) {
  return httpRequest(url, {
    method: 'GET',
    headers: { Authorization: `Bearer ${token}` },
  });
}

// ── Secrets Manager ───────────────────────────────────────────────────────────

async function getCredentials() {
  if (!CREDENTIALS_SECRET_ARN) {
    throw new Error('LAMBDA_SERVICE_CREDENTIALS_SECRET_ARN env var not set');
  }
  const response = await secretsClient.send(
    new GetSecretValueCommand({ SecretId: CREDENTIALS_SECRET_ARN })
  );
  return JSON.parse(response.SecretString);
}

// ── Auth / JWT ────────────────────────────────────────────────────────────────

function parseJwtExpiry(token) {
  try {
    const payload = JSON.parse(Buffer.from(token.split('.')[1], 'base64').toString());
    return payload.exp ? payload.exp * 1000 : 0;
  } catch {
    return 0;
  }
}

async function getToken() {
  const bufferMs = 5 * 60 * 1000; // refresh 5 min before expiry
  if (cachedToken && Date.now() < tokenExpiresAt - bufferMs) {
    console.log('Using cached JWT (expires in', Math.round((tokenExpiresAt - Date.now()) / 60000), 'min)');
    return cachedToken;
  }

  console.log('Fetching fresh credentials from Secrets Manager...');
  const creds = await getCredentials();

  console.log('Logging in as', creds.username, '...');
  const authResponse = await httpRequest(
    `${AUTH_SERVICE_URL}/api/auth/login`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    },
    JSON.stringify({ username: creds.username, password: creds.password })
  );

  cachedToken = authResponse.token;
  tokenExpiresAt = parseJwtExpiry(cachedToken) || (Date.now() + 3600 * 1000);
  console.log('JWT obtained, valid until', new Date(tokenExpiresAt).toISOString());
  return cachedToken;
}

// ── SNS publish ───────────────────────────────────────────────────────────────

async function publishAlert(topicArn, subject, message) {
  if (!topicArn) {
    console.log('SNS topic ARN not configured, skipping:', subject);
    return;
  }
  await sns.send(new PublishCommand({ TopicArn: topicArn, Subject: subject, Message: message }));
  console.log('Published to SNS:', subject);
}

// ── Handler ───────────────────────────────────────────────────────────────────

exports.handler = async (event) => {
  console.log('Alert processor triggered. Event:', JSON.stringify(event));

  if (!VEHICLE_SERVICE_URL || !AUTH_SERVICE_URL) {
    console.error('VEHICLE_SERVICE_URL or AUTH_SERVICE_URL not configured');
    return { statusCode: 500, body: 'Service URLs not configured' };
  }

  const token = await getToken();

  const [insuranceAlerts, serviceAlerts] = await Promise.all([
    fetchJson(`${VEHICLE_SERVICE_URL}/api/vehicles/alerts/insurance`, token),
    fetchJson(`${VEHICLE_SERVICE_URL}/api/vehicles/alerts/service`, token),
  ]);

  console.log(`Insurance alerts: ${insuranceAlerts.length}, Service alerts: ${serviceAlerts.length}`);

  // ── Insurance expiry broadcast ────────────────────────────────────────────
  if (insuranceAlerts.length > 0) {
    const lines = insuranceAlerts.map(v =>
      `  • ${v.vehicleNumber} (${v.brand || ''} ${v.model || ''}) — expires ${v.insuranceExpiry}`
    ).join('\n');

    const message = [
      `FleetOps Daily Alarm — Insurance Expiry`,
      `Date: ${new Date().toISOString().slice(0, 10)}`,
      ``,
      `${insuranceAlerts.length} vehicle(s) have insurance expiring within 30 days:`,
      lines,
      ``,
      `Action required: Raise an INSURANCE_RENEWAL service request for each vehicle listed above.`,
    ].join('\n');

    await publishAlert(
      INSURANCE_SNS_ARN,
      `[FleetOps ALARM] ${insuranceAlerts.length} vehicle(s) insurance expiring`,
      message
    );
  }

  // ── Service overdue broadcast ─────────────────────────────────────────────
  if (serviceAlerts.length > 0) {
    const lines = serviceAlerts.map(v =>
      `  • ${v.vehicleNumber} (${v.brand || ''} ${v.model || ''}) — ${v.currentMileage} km / ${v.nextServiceMileage} km threshold`
    ).join('\n');

    const message = [
      `FleetOps Daily Alarm — Service Overdue`,
      `Date: ${new Date().toISOString().slice(0, 10)}`,
      ``,
      `${serviceAlerts.length} vehicle(s) have exceeded their service mileage threshold:`,
      lines,
      ``,
      `Action required: Raise a ROUTINE_SERVICE service request for each vehicle listed above.`,
    ].join('\n');

    await publishAlert(
      SERVICE_SNS_ARN,
      `[FleetOps ALARM] ${serviceAlerts.length} vehicle(s) service overdue`,
      message
    );
  }

  return {
    statusCode: 200,
    body: JSON.stringify({
      insuranceAlertsPublished: insuranceAlerts.length,
      serviceAlertsPublished: serviceAlerts.length,
    }),
  };
};
