variable "project" {
  type = string
  description = "Project name"
}

variable "environment" {
  type = string
  description = "Environment name"
}

variable "kms_events_key_arn" {
  type = string
  description = "KMS Key ARN for encrypting SQS queue"
}




