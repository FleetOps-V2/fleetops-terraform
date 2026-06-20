variable "project" {
  type = string
  description = "Project name"
}

variable "environment" {
  type = string
  description = "Environment name"
}

variable "alert_processor_lambda_arn" {
  type = string
  description = "ARN of the Alert Processor Lambda to trigger"
}

variable "alert_processor_lambda_name" {
  type = string
  description = "Name of the Alert Processor Lambda"
}




