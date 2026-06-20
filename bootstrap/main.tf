terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.44.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# KMS Key for encrypting Terraform State
resource "aws_kms_key" "state_key" {
  description             = "KMS key for encrypting Terraform state in S3"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name        = "fleetops-terraform-state-key"
    Environment = "bootstrap"
  }
}

resource "aws_kms_alias" "state_key_alias" {
  name          = "alias/fleetops-terraform-state-key"
  target_key_id = aws_kms_key.state_key.key_id
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "state_bucket" {
  bucket        = var.state_bucket_name
  force_destroy = false # Prevent accidental deletion

  tags = {
    Name        = "fleetops-terraform-state"
    Environment = "bootstrap"
  }
}

# Versioning for State Bucket
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-Side Encryption for State Bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Public Access Block for State Bucket
resource "aws_s3_bucket_public_access_block" "state_public_access" {
  bucket = aws_s3_bucket.state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Object Ownership Controls
resource "aws_s3_bucket_ownership_controls" "state_ownership" {
  bucket = aws_s3_bucket.state_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# S3 Bucket Policy to enforce TLS
resource "aws_s3_bucket_policy" "state_policy" {
  bucket = aws_s3_bucket.state_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.state_bucket.arn,
          "${aws_s3_bucket.state_bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# DynamoDB Lock Table
resource "aws_dynamodb_table" "lock_table" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "fleetops-terraform-locks"
    Environment = "bootstrap"
  }
}

# ── ECR Repositories ─────────────────────────────────────────────
# Kept in bootstrap so images survive terraform destroy/apply cycles
# on the main environment. Repos are cheap; recreating them loses all
# pushed images and breaks GitOps tag references in Helm values.

locals {
  ecr_services = [
    "auth-service",
    "vehicle-service",
    "request-service",
    "maintenance-service",
    "frontend",
  ]
  ecr_operators = ["external-secrets"]

  ecr_tags = {
    Project     = "fleetops"
    Environment = "bootstrap"
    ManagedBy   = "terraform"
    Module      = "ecr"
  }
}

resource "aws_ecr_repository" "services" {
  for_each             = toset(local.ecr_services)
  name                 = "fleetops-dev/${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration { scan_on_push = true }
  encryption_configuration    { encryption_type = "AES256" }

  tags = merge(local.ecr_tags, { Name = "fleetops-dev-${each.key}" })
}

resource "aws_ecr_repository" "operators" {
  for_each             = toset(local.ecr_operators)
  name                 = each.key
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration { scan_on_push = true }
  encryption_configuration    { encryption_type = "AES256" }

  tags = merge(local.ecr_tags, { Name = each.key, Purpose = "operator-mirror" })
}

resource "aws_ecr_lifecycle_policy" "services" {
  for_each   = aws_ecr_repository.services
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Remove untagged images after 1 day"
        selection    = { tagStatus = "untagged", countType = "sinceImagePushed", countUnit = "days", countNumber = 1 }
        action       = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep last 10 tagged images (v* for prod, develop-* for dev)"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "develop"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}




