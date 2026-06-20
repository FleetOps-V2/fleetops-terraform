output "bedrock_access_policy_arn" {
  description = "ARN of the IAM policy granting Bedrock access"
  value       = aws_iam_policy.bedrock_access.arn
}




