# Secrets Manager - Database Credentials Template
resource "aws_secretsmanager_secret" "db_credentials" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation requires a rotation Lambda; managed manually for this project
  name                    = "fleetops/${var.environment}/database/credentials"
  description             = "Database credentials for FleetOps PostgreSQL"
  kms_key_id              = aws_kms_key.secrets_key.arn
  recovery_window_in_days = 7

  tags = {
    Name        = "fleetops-db-credentials-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials_placeholder" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "postgres"
    password = "change_me_in_aws_console_or_cli"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Secrets Manager - JWT Secret Key
resource "aws_secretsmanager_secret" "jwt_secret" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation requires a rotation Lambda; managed manually for this project
  name                    = "fleetops/${var.environment}/auth/jwt-secret"
  description             = "JWT Secret key for Auth Service"
  kms_key_id              = aws_kms_key.secrets_key.arn
  recovery_window_in_days = 7

  tags = {
    Name        = "fleetops-jwt-secret-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "jwt_secret_placeholder" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = "change_me_to_a_long_cryptographically_secure_key_at_least_256_bits"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Secrets Manager - Bedrock Cross-Account Credentials
resource "aws_secretsmanager_secret" "bedrock_credentials" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation requires a rotation Lambda; cross-account Bedrock credentials rotated manually
  name                    = "fleetops/${var.environment}/bedrock/credentials"
  description             = "Cross-account Bedrock IAM credentials for Nova Lite"
  kms_key_id              = aws_kms_key.secrets_key.arn
  recovery_window_in_days = 7

  tags = {
    Name        = "fleetops-bedrock-credentials-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "bedrock_credentials" {
  secret_id = aws_secretsmanager_secret.bedrock_credentials.id
  secret_string = jsonencode({
    access_key = var.bedrock_access_key
    secret_key = var.bedrock_secret_key
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# SSM Parameter Store - Redis Endpoint
resource "aws_ssm_parameter" "redis_endpoint" {
  name        = "/fleetops/${var.environment}/redis/endpoint"
  description = "Redis cache endpoint"
  type        = "SecureString"
  value       = "change_me_to_redis_hostname_or_cluster_arn"
  key_id      = aws_kms_key.secrets_key.arn

  tags = {
    Environment = var.environment
  }
}

# SSM Parameter Store - CORS Allowed Origins
resource "aws_ssm_parameter" "cors_origins" {
  #checkov:skip=CKV2_AWS_34:Non-sensitive CORS origin list; not a secret
  name        = "/fleetops/${var.environment}/cors/origins"
  description = "Comma-separated CORS allowed origins"
  type        = "String"
  value       = var.environment == "prod" ? "https://fleetops.example.com" : "http://localhost:8080,http://localhost:5173"

  tags = {
    Environment = var.environment
  }
}




