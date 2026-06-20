# ============================================================
# Variables for module: alb
# ============================================================
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "project" {
  description = "Project name prefix for all resource names"
  type        = string
  default     = "fleetops"
}




