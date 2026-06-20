variable "environment" {
  type      = string
}
variable "project" {
  type = string
  default = "fleetops"
}
variable "kms_secrets_key_arn" {
  type = string
  description = "ARN of the KMS key for Secrets Manager"
}
variable "db_host" {
  type = string
  description = "RDS endpoint address"
}
variable "db_username" {
  type        = string
  description = "RDS master username"
  sensitive = true
}
variable "db_password" {
  type      = string
  description = "RDS master password"
  sensitive = true
}
variable "jwt_secret" {
  type      = string
  description = "JWT signing secret (32+ chars)"
  sensitive = true
}
variable "github_username" {
  type      = string
  description = "GitHub username for ArgoCD repo access"
  default   = "johannabyvannilamad"
}
variable "github_pat" {
  type      = string
  description = "GitHub PAT for ArgoCD to pull fleetops-deployments"
  sensitive = true
}




