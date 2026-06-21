locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "dynamodb"
    Owner       = "FleetOps-Team"
  }
}

resource "aws_dynamodb_table" "telemetry" {
  name           = "${local.name_prefix}-vehicle-telemetry"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "vehicle_id"
  range_key      = "timestamp"

  attribute {
    name = "vehicle_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_events_key_arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = local.common_tags
}




