variable "environment" {
  type = string
}
variable "project" {
  type = string
  default = "fleetops"
}
variable "kms_s3_key_arn" {
  type = string
  description = "KMS key ARN for S3 encryption"
}
variable "frontend_origin" {
  type = string
  description = "Frontend URL for CORS e.g. https://fleetops.website"
  default = "https://fleetops.website"
}




