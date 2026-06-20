# ============================================================
# Module: sns
# Phase:  4
# Description: Insurance expiry alerts, service due alerts
# ============================================================

locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "sns"
    Owner       = "FleetOps-Team"
  }
}

resource "aws_sns_topic" "insurance_alerts" {
  name              = "${local.name_prefix}-insurance-alerts"
  kms_master_key_id = var.kms_sns_key_arn
  tags              = local.common_tags
}

resource "aws_sns_topic" "service_alerts" {
  name              = "${local.name_prefix}-service-alerts"
  kms_master_key_id = var.kms_sns_key_arn
  tags              = local.common_tags
}

# Add IAM policy to allow CloudWatch and EventBridge to publish to SNS
resource "aws_sns_topic_policy" "insurance_alerts" {
  arn = aws_sns_topic.insurance_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudWatchEvents"
        Effect    = "Allow"
        Principal = { Service = ["events.amazonaws.com", "cloudwatch.amazonaws.com"] }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.insurance_alerts.arn
      }
    ]
  })
}

resource "aws_sns_topic_policy" "service_alerts" {
  arn = aws_sns_topic.service_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudWatchEvents"
        Effect    = "Allow"
        Principal = { Service = ["events.amazonaws.com", "cloudwatch.amazonaws.com"] }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.service_alerts.arn
      }
    ]
  })
}




