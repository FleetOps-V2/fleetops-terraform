#!/bin/bash
# =============================================================
# FleetOps EKS Worker Node Bootstrap Script
# Purpose : Runs on EC2 nodes joining the EKS Managed Node Group
# Installs: AWS CLI v2, kubectl, ECR credential helper
# Seeds   : Database via psql after Flyway runs (triggered by app)
# Note    : Flyway handles schema. This script only seeds data
#           if the tables are empty (idempotent guard).
# =============================================================

set -euo pipefail
exec > >(tee /var/log/fleetops-bootstrap.log) 2>&1

echo "=== FleetOps EKS Node Bootstrap started at $(date) ==="

# ── 1. System updates ──────────────────────────────────────────
yum update -y
yum install -y aws-cli postgresql15 jq curl

# ── 2. Install kubectl ─────────────────────────────────────────
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/kubectl

# ── 3. Configure AWS region ────────────────────────────────────
export AWS_DEFAULT_REGION="${aws_region}"

# ── 4. Fetch DB credentials from Secrets Manager ──────────────
echo "=== Fetching database credentials from Secrets Manager ==="
DB_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "${db_secret_arn}" \
  --query SecretString \
  --output text)

DB_HOST=$(echo "$DB_SECRET" | jq -r '.host')
DB_PORT=$(echo "$DB_SECRET" | jq -r '.port')
DB_NAME=$(echo "$DB_SECRET" | jq -r '.dbname')
DB_USER=$(echo "$DB_SECRET" | jq -r '.username')
DB_PASS=$(echo "$DB_SECRET" | jq -r '.password')

export PGPASSWORD="$DB_PASS"

echo "=== DB host: $DB_HOST ==="

# ── 5. Wait for RDS to be reachable ───────────────────────────
echo "=== Waiting for RDS to be available ==="
for i in $(seq 1 30); do
  pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" && break
  echo "Attempt $i: RDS not ready yet, waiting 10s..."
  sleep 10
done

# ── 6. Seed users into auth_db (idempotent) ───────────────────
echo "=== Seeding auth_db (users) ==="
USER_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d auth_db -tAc \
  "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "0")

if [ "$USER_COUNT" -eq "0" ]; then
  echo "Users table is empty — running seed..."
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d auth_db \
    -f /opt/fleetops/seeds/seed-users.sql
  echo "Users seeded successfully."
else
  echo "Users table already has $USER_COUNT rows — skipping seed."
fi

# ── 7. Seed vehicles into vehicle_db (idempotent) ─────────────
echo "=== Seeding vehicle_db ==="
VEHICLE_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d vehicle_db -tAc \
  "SELECT COUNT(*) FROM vehicles;" 2>/dev/null || echo "0")

if [ "$VEHICLE_COUNT" -eq "0" ]; then
  echo "Vehicles table is empty — running seed..."
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d vehicle_db \
    -f /opt/fleetops/seeds/seed.sql
  echo "Vehicles seeded successfully."
else
  echo "Vehicles table already has $VEHICLE_COUNT rows — skipping seed."
fi

# ── 8. Seed maintenance into maintenance_db (idempotent) ──────
echo "=== Seeding maintenance_db ==="
MAINT_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d maintenance_db -tAc \
  "SELECT COUNT(*) FROM maintenance_queues;" 2>/dev/null || echo "0")

if [ "$MAINT_COUNT" -eq "0" ]; then
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d maintenance_db \
    -f /opt/fleetops/seeds/seed-maintenance.sql
  echo "Maintenance queues seeded."
else
  echo "Maintenance already seeded — skipping."
fi

# ── 9. Seed requests into request_db (idempotent) ─────────────
echo "=== Seeding request_db ==="
REQ_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d request_db -tAc \
  "SELECT COUNT(*) FROM service_requests;" 2>/dev/null || echo "0")

if [ "$REQ_COUNT" -eq "0" ]; then
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d request_db \
    -f /opt/fleetops/seeds/seed-requests.sql
  echo "Service requests seeded."
else
  echo "Service requests already seeded — skipping."
fi

echo "=== FleetOps EKS Node Bootstrap completed at $(date) ==="
