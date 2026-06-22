variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "service_alerts_topic_arn" {
  type        = string
  description = "ARN of the SNS topic for service alerts"
}

variable "rds_instance_identifier" {
  type        = string
  description = "Identifier of the RDS instance to monitor"
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of KMS key for CloudWatch log group encryption"
}

variable "lambda_function_name" {
  type        = string
  description = "Name of the alert processor Lambda function to monitor for errors."
}

variable "alb_arn_suffix" {
  type        = string
  description = "ARN suffix of the ALB (e.g. app/k8s-fleetops-.../abc123). Leave empty until ALB exists — alarm is skipped when empty."
  default     = ""
}
