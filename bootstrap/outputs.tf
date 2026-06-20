output "state_bucket_name" {
  value       = aws_s3_bucket.state_bucket.id
  description = "The name of the S3 bucket for storing Terraform state"
}

output "state_bucket_arn" {
  value       = aws_s3_bucket.state_bucket.arn
  description = "The ARN of the S3 bucket for storing Terraform state"
}

output "lock_table_name" {
  value       = aws_dynamodb_table.lock_table.name
  description = "The name of the DynamoDB table for state locking"
}

output "lock_table_arn" {
  value       = aws_dynamodb_table.lock_table.arn
  description = "The ARN of the DynamoDB table for state locking"
}

output "kms_key_arn" {
  value       = aws_kms_key.state_key.arn
  description = "The ARN of the KMS key used for state encryption"
}

output "ecr_repository_urls" {
  description = "Map of service name → ECR repository URL"
  value       = { for name, repo in aws_ecr_repository.services : name => repo.repository_url }
}

output "ecr_operator_urls" {
  description = "Map of operator name → ECR repository URL"
  value       = { for name, repo in aws_ecr_repository.operators : name => repo.repository_url }
}




