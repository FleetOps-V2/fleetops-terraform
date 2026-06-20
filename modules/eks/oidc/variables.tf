variable "environment" {
  type = string
}
variable "project" {
  type = string
  default = "fleetops"
}
variable "oidc_issuer_url" {
  type = string
  description = "OIDC issuer URL from eks/cluster output"
}




