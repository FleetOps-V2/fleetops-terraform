variable "environment" {
  type = string
}
variable "project" {
  type = string
  default = "fleetops"
}
variable "private_subnet_ids" {
  type = list(string)
}
variable "redis_sg_id" {
  type = string
}
variable "redis_node_type" {
  type = string
  default = "cache.t3.micro"
}




