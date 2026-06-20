variable "aws_region" {
  type = string
  default     = "us-east-1"
  description = "AWS region for provisioning bootstrap resources"
}

variable "state_bucket_name" {
  type = string
  default     = "fleetops-terraform-state-johan"
  description = "Name of the S3 bucket to store Terraform state"
}

variable "lock_table_name" {
  type = string
  default     = "fleetops-terraform-locks"
  description = "Name of the DynamoDB table for state locking"
}




