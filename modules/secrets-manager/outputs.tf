output "db_secret_arn" { value = aws_secretsmanager_secret.db.arn }
output "jwt_secret_arn" { value = aws_secretsmanager_secret.jwt.arn }
output "lambda_service_credentials_arn" {
  value       = aws_secretsmanager_secret.lambda_service_credentials.arn
  description = "ARN of the lambda-service credentials secret (username + password)"
}
output "lambda_service_password" {
  value     = random_password.lambda_service.result
  sensitive = true
}




