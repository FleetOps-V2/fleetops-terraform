variable "environment" {
  type = string
}
variable "project" {
  type    = string
  default = "fleetops"
}
variable "db_subnet_ids" {
  type        = list(string)
  description = "IDs of the isolated database subnets for the ElastiCache subnet group"
}
variable "redis_sg_id" {
  type = string
}
variable "redis_node_type" {
  type    = string
  default = "cache.t3.micro"
}




