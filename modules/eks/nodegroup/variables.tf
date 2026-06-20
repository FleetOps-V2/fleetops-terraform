variable "environment" {
  type = string
}
variable "project" {
  type = string
  default = "fleetops"
}
variable "cluster_name" {
  type = string
}
variable "node_role_arn" {
  type = string
}
variable "private_subnet_ids" {
  type = list(string)
}
variable "node_instance_type" {
  type = string
  default = "t3.small"
}
variable "min_size" {
  type = number
  default = 1
}
variable "max_size" {
  type = number
  default = 3
}
variable "desired_size" {
  type = number
  default = 2
}




