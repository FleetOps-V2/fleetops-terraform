locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "eventbridge"
    Owner       = "FleetOps-Team"
  }
}

resource "aws_cloudwatch_event_rule" "daily_maintenance_scan" {
  name                = "${local.name_prefix}-daily-maintenance-scan"
  description         = "Triggers the maintenance scan daily"
  schedule_expression = "rate(1 day)"
  tags                = local.common_tags
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.daily_maintenance_scan.name
  target_id = "TriggerAlertProcessorLambda"
  arn       = var.alert_processor_lambda_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.alert_processor_lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_maintenance_scan.arn
}




