variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "eks_account_app_role_arn" {
  type        = string
  description = "ARN of the IRSA role in Account A (EKS account) that will assume this role"
}
