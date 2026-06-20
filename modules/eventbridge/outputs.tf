output "daily_maintenance_scan_rule_arn" {
  description = "ARN of the Daily Maintenance Scan EventBridge Rule"
  value       = aws_cloudwatch_event_rule.daily_maintenance_scan.arn
}




