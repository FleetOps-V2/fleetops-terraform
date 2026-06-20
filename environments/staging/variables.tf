variable "aws_region" {
  type = string
  description = "The AWS region to provision resources in"
}

variable "environment" {
  type = string
  description = "The environment name (e.g. dev, prod)"
}

variable "vpc_cidr" {
  type = string
  description = "CIDR block for the VPC"
}

variable "enable_deletion_protection" {
  type = bool
  description = "Enable deletion protection for the RDS database"
}

variable "db_instance_class" {
  type = string
  description = "RDS database instance class"
}




