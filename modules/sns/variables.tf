variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "kms_sns_key_arn" {
  type        = string
  description = "KMS Key ARN for encrypting SNS topics"
}

variable "alert_emails" {
  type        = list(string)
  description = "Email addresses to subscribe to both alert topics (insurance + service). Each address receives a confirmation email after apply."
  default     = []
}




