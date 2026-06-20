output "dashboard_arn" {
  description = "ARN of the CloudWatch Dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "rds_cpu_alarm_arn" {
  description = "ARN of the RDS CPU Alarm"
  value       = aws_cloudwatch_metric_alarm.rds_cpu_high.arn
}




