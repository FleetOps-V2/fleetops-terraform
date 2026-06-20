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
variable "efs_sg_id" {
  type = string
  description = "Security group allowing NFS port 2049 from EKS nodes"
}
variable "kms_s3_key_arn" {
  type = string
  description = "KMS key for EFS encryption (reuse S3 CMK)"
}




