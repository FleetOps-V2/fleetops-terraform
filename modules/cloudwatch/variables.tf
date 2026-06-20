variable "project" {
  type = string
  description = "Project name"
}

variable "environment" {
  type = string
  description = "Environment name"
}

variable "service_alerts_topic_arn" {
  type = string
  description = "ARN of the SNS topic for service alerts"
}

variable "rds_instance_identifier" {
  type = string
  description = "Identifier of the RDS instance to monitor"
}




