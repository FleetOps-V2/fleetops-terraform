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
  description = "ARN of KMS key for Step Functions CloudWatch log group encryption"
}
