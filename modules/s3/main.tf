locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "s3"
    Owner       = "FleetOps-Team"
  }
}

resource "aws_s3_bucket" "vehicle_docs" {
  bucket = "${local.name_prefix}-vehicle-docs"
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-vehicle-docs" })
}

resource "aws_s3_bucket_public_access_block" "vehicle_docs" {
  bucket                  = aws_s3_bucket.vehicle_docs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vehicle_docs" {
  bucket = aws_s3_bucket.vehicle_docs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_s3_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "vehicle_docs" {
  bucket = aws_s3_bucket.vehicle_docs.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_lifecycle_configuration" "vehicle_docs" {
  bucket = aws_s3_bucket.vehicle_docs.id

  rule {
    id     = "archive-old-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "vehicle_docs" {
  bucket = aws_s3_bucket.vehicle_docs.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = [var.frontend_origin]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}




