variable "environment" {
  type    = string
  default = "prod"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "domain_name" {
  type    = string
  default = "fleetops.website"
}

# ── Networking ────────────────────────────────────────────────

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the production VPC"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.2.1.0/24", "10.2.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.2.10.0/24", "10.2.11.0/24"]
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

# ── Database ──────────────────────────────────────────────────

variable "db_instance_class" {
  type    = string
  default = "db.t3.small"
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

# ── Cache ─────────────────────────────────────────────────────

variable "redis_node_type" {
  type    = string
  default = "cache.t3.micro"
}

# ── Secrets ───────────────────────────────────────────────────

variable "jwt_secret" {
  type      = string
  sensitive = true
}

variable "github_pat" {
  type        = string
  sensitive   = true
  description = "GitHub PAT for ArgoCD to pull fleetops-deployments (stored in Secrets Manager)"
}

# ── EKS ──────────────────────────────────────────────────────

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
  default = 2
}

variable "eks_node_max_size" {
  type    = number
  default = 5
}

variable "eks_node_desired_size" {
  type    = number
  default = 3
}

variable "k8s_namespace" {
  type    = string
  default = "fleetops-prod"
}

variable "k8s_service_account_name" {
  type    = string
  default = "fleetops-app"
}

variable "admin_iam_user_arns" {
  type        = list(string)
  default     = []
  description = "IAM user ARNs to grant EKS cluster-admin access."
}

variable "eks_public_access_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDR ranges allowed to reach the EKS API server. Restrict in production."
}

# ── ArgoCD & Services ─────────────────────────────────────────

variable "argocd_repo_url" {
  type    = string
  default = "https://github.com/FleetOps-V2/fleetops-deployments.git"
}

variable "origin_alb_dns" {
  type        = string
  default     = ""
  description = "DNS of the K8s-managed ALB. Empty until first Ingress is deployed."
}

variable "vehicle_service_url" {
  type    = string
  default = "http://fleetops-vehicle-service:8080"
}

variable "auth_service_url" {
  type    = string
  default = "http://fleetops-auth-service:8080"
}

variable "bedrock_access_key" {
  type      = string
  sensitive = true
}

variable "bedrock_secret_key" {
  type      = string
  sensitive = true
}
