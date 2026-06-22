output "dashboard_arn" {
  description = "ARN of the CloudWatch Dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "rds_cpu_alarm_arn" {
  description = "ARN of the RDS CPU Alarm"
  value       = aws_cloudwatch_metric_alarm.rds_cpu_high.arn
}

output "rds_connections_alarm_arn" {
  description = "ARN of the RDS DB Connections Alarm"
  value       = aws_cloudwatch_metric_alarm.rds_connections_high.arn
}

output "alb_5xx_alarm_arn" {
  description = "ARN of the ALB 5xx Error Rate Alarm (empty string when alb_arn_suffix is not set)"
  value       = length(aws_cloudwatch_metric_alarm.alb_5xx_high) > 0 ? aws_cloudwatch_metric_alarm.alb_5xx_high[0].arn : ""
}

output "lambda_errors_alarm_arn" {
  description = "ARN of the Lambda Alert Processor Errors Alarm"
  value       = aws_cloudwatch_metric_alarm.lambda_errors.arn
}




