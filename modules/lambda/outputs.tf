output "alert_processor_function_arn" {
  description = "ARN of the Alert Processor Lambda"
  value       = aws_lambda_function.alert_processor.arn
}

output "metadata_extractor_function_arn" {
  description = "ARN of the Metadata Extractor Lambda"
  value       = aws_lambda_function.metadata_extractor.arn
}

output "alert_processor_function_name" {
  description = "Name of the Alert Processor Lambda"
  value       = aws_lambda_function.alert_processor.function_name
}




