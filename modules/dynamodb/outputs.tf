output "telemetry_table_name" {
  description = "Name of the DynamoDB Telemetry Table"
  value       = aws_dynamodb_table.telemetry.name
}

output "telemetry_table_arn" {
  description = "ARN of the DynamoDB Telemetry Table"
  value       = aws_dynamodb_table.telemetry.arn
}




