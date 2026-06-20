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
variable "cluster_name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "oidc_provider_url" {
  type        = string
  description = "OIDC provider URL without https:// (from eks/oidc output)"
}

variable "argocd_repo_url" {
  type        = string
  description = "Git repository URL for the ArgoCD root application."
}

variable "kms_secrets_key_arn" {
  type        = string
  description = "ARN of the KMS key used to encrypt Secrets Manager secrets (for ESO decrypt)"
  default     = ""
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN attached to the ALB HTTPS listener (wildcard *.fleetops.website)"
}

variable "alb_sg_id" {
  type        = string
  description = "Security group ID for the ALB — controls which traffic reaches the load balancer"
}

variable "domain_name" {
  type        = string
  description = "Base domain name (e.g. fleetops.website) — used to construct the ArgoCD hostname"
}




