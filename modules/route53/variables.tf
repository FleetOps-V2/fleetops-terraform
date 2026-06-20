variable "environment" {
  type = string
}
variable "project" {
  type = string
  default = "fleetops"
}
variable "domain_name" {
  type = string
  default = "fleetops.website"
}
variable "alb_dns_name" {
  type = string
  default = ""
  description = "ALB DNS name — set in Phase 2B"
}
variable "alb_zone_id" {
  type = string
  default = ""
  description = "ALB hosted zone ID — set in Phase 2B"
}




