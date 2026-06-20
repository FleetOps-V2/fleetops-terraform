variable "environment" {
  type = string
}
variable "project" {
  type = string
  default = "fleetops"
}
variable "aws_region" {
  type = string
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

variable "dynamodb_telemetry_arn" {
  type = string
  description = "ARN of the DynamoDB telemetry table"
  default     = ""
}

variable "sqs_gps_queue_arn" {
  type = string
  description = "ARN of the SQS GPS tracking queue"
  default     = ""
}

variable "sns_alerts_topic_arn" {
  type = string
  description = "ARN of the SNS alerts topic"
  default     = ""
}

variable "bedrock_policy_arn" {
  type = string
  description = "ARN of the Bedrock access policy"
  default     = ""
}

variable "github_repo" {
  type        = string
  description = "GitHub repository in 'org/repo' format allowed to assume the GitHub Actions role."
  default     = "FleetOps-V2/fleetops-infra"
}




