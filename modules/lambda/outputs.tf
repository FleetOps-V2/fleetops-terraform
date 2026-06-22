output "alert_processor_function_arn" {
  description = "ARN of the Alert Processor Lambda"
  value       = aws_lambda_function.alert_processor.arn
}

output "alert_processor_function_name" {
  description = "Name of the Alert Processor Lambda"
  value       = aws_lambda_function.alert_processor.function_name
}




