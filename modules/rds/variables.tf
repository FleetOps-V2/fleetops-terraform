variable "environment" {
  type      = string
}
variable "project" {
  type = string
  default = "fleetops"
}
variable "private_subnet_ids" {
  type = list(string)
}
variable "rds_sg_id" {
  type = string
}
variable "kms_rds_key_arn" {
  type = string
}
variable "db_instance_class" {
  type = string
  default = "db.t3.micro"
}
variable "db_username" {
  type = string
  sensitive = true
}
variable "db_password" {
  type      = string
  sensitive = true
}
variable "enable_deletion_protection" {
  type = bool
  default = false
}





