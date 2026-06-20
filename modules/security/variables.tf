variable "environment" {
  type = string
  description = "The environment name (e.g., dev, prod)"
}

variable "aws_region" {
  type = string
  description = "AWS region"
}

variable "bedrock_access_key" {
  description = "Cross-account Bedrock IAM access key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "bedrock_secret_key" {
  description = "Cross-account Bedrock IAM secret key"
  type        = string
  sensitive   = true
  default     = ""
}




