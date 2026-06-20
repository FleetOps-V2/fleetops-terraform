variable "project" {
  type = string
  description = "Project name"
}

variable "environment" {
  type = string
  description = "Environment name"
}

variable "kms_sns_key_arn" {
  type = string
  description = "KMS Key ARN for encrypting SNS topics"
}




