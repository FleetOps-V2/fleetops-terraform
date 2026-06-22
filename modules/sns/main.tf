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

resource "aws_sns_topic_subscription" "insurance_alerts_email" {
  for_each  = toset(var.alert_emails)
  topic_arn = aws_sns_topic.insurance_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_sns_topic_subscription" "service_alerts_email" {
  for_each  = toset(var.alert_emails)
  topic_arn = aws_sns_topic.service_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}




