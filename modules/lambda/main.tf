locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "lambda"
    Owner       = "FleetOps-Team"
  }
}

data "archive_file" "dummy_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda_function_payload.zip"
}

# 1. Alert Processor Lambda
resource "aws_lambda_function" "alert_processor" {
  #checkov:skip=CKV_AWS_115:Concurrent execution limit not required for alert processing
  #checkov:skip=CKV_AWS_116:DLQ not required; failures are surfaced via CloudWatch alarms
  #checkov:skip=CKV_AWS_117:Lambda calls external APIs over HTTPS; VPC adds latency without security benefit
  #checkov:skip=CKV_AWS_272:Code-signing not implemented for this training project
  #checkov:skip=CKV_AWS_173:Env vars contain resource ARNs/URLs, not secrets; secrets are in Secrets Manager
  filename         = data.archive_file.dummy_lambda.output_path
  function_name    = "${local.name_prefix}-alert-processor"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.dummy_lambda.output_base64sha256
  runtime          = "nodejs22.x"

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      ENVIRONMENT                           = var.environment
      VEHICLE_SERVICE_URL                   = var.vehicle_service_url
      AUTH_SERVICE_URL                      = var.auth_service_url
      LAMBDA_SERVICE_CREDENTIALS_SECRET_ARN = var.lambda_service_credentials_secret_arn
      INSURANCE_SNS_ARN                     = var.insurance_sns_arn
      SERVICE_SNS_ARN                       = var.service_sns_arn
    }
  }

  # Placeholder zip hash differs between Windows (local) and Linux (CI/CD) runners.
  # Real Lambda code is deployed via service CI/CD pipelines, not Terraform.
  lifecycle {
    ignore_changes = [source_code_hash, last_modified]
  }

  tags = local.common_tags
}

# 2. Document Metadata Extractor Lambda
resource "aws_lambda_function" "metadata_extractor" {
  #checkov:skip=CKV_AWS_115:Concurrent execution limit not required for metadata extraction
  #checkov:skip=CKV_AWS_116:DLQ not required; failures are surfaced via CloudWatch alarms
  #checkov:skip=CKV_AWS_117:Lambda reads S3 events; VPC not required for this use case
  #checkov:skip=CKV_AWS_272:Code-signing not implemented for this training project
  #checkov:skip=CKV_AWS_173:Env vars contain non-secret configuration only
  filename         = data.archive_file.dummy_lambda.output_path
  function_name    = "${local.name_prefix}-metadata-extractor"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.dummy_lambda.output_base64sha256
  runtime          = "nodejs22.x"

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  lifecycle {
    ignore_changes = [source_code_hash, last_modified]
  }

  tags = local.common_tags
}
