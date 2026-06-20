output "insurance_alerts_topic_arn" {
  description = "ARN of the Insurance Alerts SNS Topic"
  value       = aws_sns_topic.insurance_alerts.arn
}

output "service_alerts_topic_arn" {
  description = "ARN of the Service Alerts SNS Topic"
  value       = aws_sns_topic.service_alerts.arn
}




