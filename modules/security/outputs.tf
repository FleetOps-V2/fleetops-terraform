output "s3_documents_key_arn" {
  value       = aws_kms_key.s3_documents_key.arn
  description = "ARN of the S3 documents encryption key"
}

output "database_key_arn" {
  value       = aws_kms_key.database_key.arn
  description = "ARN of the database encryption key"
}

output "secrets_key_arn" {
  value       = aws_kms_key.secrets_key.arn
  description = "ARN of the secrets encryption key"
}

output "state_key_arn" {
  value       = aws_kms_key.state_key.arn
  description = "ARN of the state encryption key"
}

output "ec2_role_arn" {
  value       = aws_iam_role.ec2_role.arn
  description = "ARN of the FleetOps EC2 IAM Role"
}

output "ecs_execution_role_arn" {
  value       = aws_iam_role.ecs_execution_role.arn
  description = "ARN of the FleetOps ECS Execution IAM Role"
}

output "ecs_task_role_arn" {
  value       = aws_iam_role.ecs_task_role.arn
  description = "ARN of the FleetOps ECS Task IAM Role"
}

output "lambda_role_arn" {
  value       = aws_iam_role.lambda_role.arn
  description = "ARN of the FleetOps Lambda IAM Role"
}




