locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "sqs"
    Owner       = "FleetOps-Team"
  }
}

resource "aws_sqs_queue" "gps_tracking_dlq" {
  name              = "${local.name_prefix}-gps-tracking-dlq"
  kms_master_key_id = var.kms_events_key_arn
  tags              = local.common_tags
}

resource "aws_sqs_queue" "gps_tracking" {
  name              = "${local.name_prefix}-gps-tracking"
  kms_master_key_id = var.kms_events_key_arn

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.gps_tracking_dlq.arn
    maxReceiveCount     = 4
  })

  tags = local.common_tags
}

# Allow EKS pods (via IRSA role) to send/receive messages.
# We will do this by exporting the queue ARN and updating the IAM module IRSA policies.




