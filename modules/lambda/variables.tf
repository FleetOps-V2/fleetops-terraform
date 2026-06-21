variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "lambda_role_arn" {
  type        = string
  description = "IAM Role ARN for Lambda Execution"
}

variable "vehicle_service_url" {
  type        = string
  description = "Internal URL of the vehicle service (e.g. http://vehicle-service:8080)"
  default     = ""
}

variable "auth_service_url" {
  type        = string
  description = "Internal URL of the auth service for Lambda JWT login"
  default     = ""
}

variable "lambda_service_credentials_secret_arn" {
  type        = string
  description = "Secrets Manager ARN containing lambda-service username + password"
  default     = ""
}

variable "insurance_sns_arn" {
  type        = string
  description = "ARN of the SNS topic for insurance expiry alerts"
  default     = ""
}

variable "service_sns_arn" {
  type        = string
  description = "ARN of the SNS topic for service overdue alerts"
  default     = ""
}

