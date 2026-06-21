output "rds_key_arn" { value = aws_kms_key.rds.arn }
output "rds_key_id" { value = aws_kms_key.rds.key_id }
output "secrets_key_arn" { value = aws_kms_key.secrets.arn }
output "s3_key_arn" { value = aws_kms_key.s3.arn }
output "terraform_state_key_arn" { value = aws_kms_key.terraform_state.arn }

# Convenience: list of all key ARNs — passed to iam module kms_key_arns variable
output "all_key_arns" {
  value = [
    aws_kms_key.rds.arn,
    aws_kms_key.secrets.arn,
    aws_kms_key.s3.arn,
    aws_kms_key.terraform_state.arn,
    aws_kms_key.events.arn,
  ]
}

output "events_key_arn" {
  description = "ARN of the KMS key for Events/SNS/SQS"
  value       = aws_kms_key.events.arn
}




