variable "environment" {
  type = string
}
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "domain_name" {
  type    = string
  default = "fleetops.website"
}

# Networking
variable "vpc_cidr" {
  type = string
}
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}
variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

# Database
variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "db_username" {
  type      = string
  sensitive = true
}
variable "db_password" {
  type      = string
  sensitive = true
}
variable "enable_deletion_protection" {
  type    = bool
  default = false
}

# Cache
variable "redis_node_type" {
  type    = string
  default = "cache.t3.micro"
}

# Secrets
variable "jwt_secret" {
  type      = string
  sensitive = true
}

# EKS — Phase 2B (defaults allow plan to succeed before EKS exists)
variable "eks_cluster_version" {
  type    = string
  default = "1.31"
}
variable "eks_node_instance_type" {
  type    = string
  default = "m7i-flex.large"
}
variable "eks_node_min_size" {
  type    = number
  default = 1
}
variable "eks_node_max_size" {
  type    = number
  default = 3
}
variable "eks_node_desired_size" {
  type    = number
  default = 2
}
variable "oidc_provider_url" {
  type    = string
  default = ""
}
variable "k8s_namespace" {
  type    = string
  default = "fleetops-prod"
}
variable "k8s_service_account_name" {
  type    = string
  default = "fleetops-app"
}

# Admin users granted cluster-admin via EKS Access Entries.
# Avoids hardcoding ARNs in module calls.
variable "admin_iam_user_arns" {
  type        = list(string)
  default     = []
  description = "IAM user ARNs to grant EKS cluster-admin access."
}

# Restrict the EKS public API endpoint to known CIDRs (VPN, bastion, CI runner).
# Default allows all IPs — tighten before going to production.
variable "eks_public_access_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDR ranges allowed to reach the EKS API server. Restrict in production."
}

variable "github_pat" {
  type        = string
  sensitive   = true
  description = "GitHub PAT for ArgoCD to pull fleetops-deployments (stored in Secrets Manager)"
}

variable "argocd_repo_url" {
  type        = string
  default     = "https://github.com/FleetOps-V2/fleetops-deployments.git"
  description = "Git repository URL for the ArgoCD root application."
}

# Set this after first K8s deploy: kubectl get ingress -n fleetops -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
# Leave empty on first apply — the Route53 alias record is skipped until the ALB exists.
variable "origin_alb_dns" {
  type        = string
  default     = ""
  description = "DNS of the K8s-managed ALB. Empty until first Ingress is deployed."
}

variable "vehicle_service_url" {
  type        = string
  default     = "http://vehicle-service:8080"
  description = "Internal cluster URL of the vehicle service for Lambda alert scanning."
}

variable "auth_service_url" {
  type        = string
  default     = "http://auth-service:8080"
  description = "Internal cluster URL of the auth service for Lambda JWT login."
}






