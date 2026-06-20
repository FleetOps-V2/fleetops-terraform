# KMS Key for Application S3 Documents
resource "aws_kms_key" "s3_documents_key" {
  description             = "KMS key for encrypting app documents in S3"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name        = "fleetops-s3-documents-key-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "s3_documents_alias" {
  name          = "alias/fleetops-s3-documents-key-${var.environment}"
  target_key_id = aws_kms_key.s3_documents_key.key_id
}

# KMS Key for Database
resource "aws_kms_key" "database_key" {
  description             = "KMS key for encrypting RDS PostgreSQL database"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name        = "fleetops-database-key-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "database_alias" {
  name          = "alias/fleetops-database-key-${var.environment}"
  target_key_id = aws_kms_key.database_key.key_id
}

# KMS Key for Secrets (Secrets Manager and SSM Parameter Store)
resource "aws_kms_key" "secrets_key" {
  description             = "KMS key for encrypting Secrets Manager and SSM parameters"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name        = "fleetops-secrets-key-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "secrets_alias" {
  name          = "alias/fleetops-secrets-key-${var.environment}"
  target_key_id = aws_kms_key.secrets_key.key_id
}

# KMS Key for Terraform Remote State (environment-specific state encryption)
resource "aws_kms_key" "state_key" {
  description             = "KMS key for encrypting Terraform state files in S3"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name        = "fleetops-terraform-state-key-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "state_alias" {
  name          = "alias/fleetops-terraform-state-key-${var.environment}"
  target_key_id = aws_kms_key.state_key.key_id
}




