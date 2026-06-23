output "bedrock_invoke_role_arn" {
  description = "ARN of BedrockInvokeRole — copy this to bedrock_invoke_role_arn in Account A prod.auto.tfvars"
  value       = aws_iam_role.bedrock_invoke.arn
}
