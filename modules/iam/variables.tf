variable "environment" {
  type = string
}
variable "project" {
  type    = string
  default = "fleetops"
}
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "oidc_provider_url" {
  description = "OIDC provider URL from the EKS cluster (without https://)"
  type        = string
  default     = "" # Populated after EKS cluster is created in Phase 2B
}

variable "k8s_namespace" {
  description = "Kubernetes namespace where the app ServiceAccount lives"
  type        = string
  default     = "fleetops-prod"
}

variable "k8s_service_account_name" {
  description = "Kubernetes ServiceAccount name to bind IRSA to"
  type        = string
  default     = "fleetops-app"
}

variable "kms_key_arns" {
  description = "List of KMS key ARNs the app role is allowed to use"
  type        = list(string)
  default     = []
}

variable "sns_alerts_topic_arn" {
  type        = string
  description = "ARN of the SNS alerts topic"
  default     = ""
}

variable "github_repo" {
  type        = string
  description = "GitHub repository in 'org/repo' format allowed to assume the GitHub Actions role."
  default     = "FleetOps-V2/fleetops-terraform"
}

variable "bedrock_invoke_role_arn" {
  type        = string
  description = "ARN of BedrockInvokeRole in Account B. When set, the app IRSA role gets sts:AssumeRole to invoke Bedrock cross-account."
  default     = ""
}




