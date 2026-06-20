output "environment" {
  value       = var.environment
  description = "The environment name"
}

output "aws_region" {
  value       = var.aws_region
  description = "The AWS region"
}

output "security_module_outputs" {
  value       = module.security
  description = "Outputs from the security module"
}




