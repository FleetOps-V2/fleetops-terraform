# =============================================================
# Module: kms  |  Phase: 2A
# 4 Customer Managed Keys — one per concern
# Separation ensures a compromised key doesn't expose everything
# =============================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "kms"
    Owner       = "FleetOps-Team"
  }
  key_policy_root = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "RootAdministration"
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
      Action    = "kms:*"
      Resource  = "*"
    }]
  })
}

# ── RDS Encryption Key ────────────────────────────────────────
resource "aws_kms_key" "rds" {
  description             = "FleetOps RDS PostgreSQL encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = local.key_policy_root
  tags                    = merge(local.common_tags, { Name = "${local.name_prefix}-rds-key" })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${local.name_prefix}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# ── Secrets Manager Encryption Key ───────────────────────────
resource "aws_kms_key" "secrets" {
  description             = "FleetOps Secrets Manager encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = local.key_policy_root
  tags                    = merge(local.common_tags, { Name = "${local.name_prefix}-secrets-key" })
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${local.name_prefix}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

# ── S3 Documents Encryption Key ───────────────────────────────
resource "aws_kms_key" "s3" {
  description             = "FleetOps S3 vehicle documents encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = local.key_policy_root
  tags                    = merge(local.common_tags, { Name = "${local.name_prefix}-s3-key" })
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${local.name_prefix}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# ── Terraform State Encryption Key ────────────────────────────
resource "aws_kms_key" "terraform_state" {
  description             = "FleetOps Terraform remote state encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = local.key_policy_root
  tags                    = merge(local.common_tags, { Name = "${local.name_prefix}-tfstate-key" })
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/${local.name_prefix}-tfstate"
  target_key_id = aws_kms_key.terraform_state.key_id
}

# Event/Observability Encryption Key
resource "aws_kms_key" "events" {
  description             = "FleetOps Events, SQS, SNS, DynamoDB encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "Allow EventBridge to use the key"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource  = "*"
      },
      {
        Sid    = "Allow CloudWatch and CloudTrail to use the key"
        Effect = "Allow"
        Principal = {
          Service = ["cloudwatch.amazonaws.com", "cloudtrail.amazonaws.com"]
        }
        Action   = ["kms:Decrypt", "kms:GenerateDataKey*", "kms:DescribeKey"]
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs to use the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action   = ["kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:Describe*"]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      }
    ]
  })
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-events-key" })
}

resource "aws_kms_alias" "events" {
  name          = "alias/${local.name_prefix}-events"
  target_key_id = aws_kms_key.events.key_id
}




