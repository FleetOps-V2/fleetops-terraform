variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of KMS key for CloudTrail log encryption"
}

variable "sns_topic_arn" {
  type        = string
  description = "ARN of SNS topic for CloudTrail notifications"
  default     = ""
}
