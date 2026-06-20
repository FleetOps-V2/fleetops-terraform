variable "environment" {
  type = string
}
variable "project" {
  type = string
  default = "fleetops"
}
variable "eks_cluster_version" {
  type    = string
  default = "1.31"
}
variable "eks_cluster_role_arn" {
  type = string
  default = ""
}
variable "public_subnet_ids" {
  type = list(string)
}
variable "private_subnet_ids" {
  type = list(string)
}
variable "control_plane_sg_id" {
  type = string
}



variable "admin_iam_user_arns" {
  type    = list(string)
  default = []
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the EKS API server publicly. Restrict to your VPN/bastion IP in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
