locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "step-functions"
    Owner       = "FleetOps-Team"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "sfn" {
  name = "${local.name_prefix}-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_sfn_state_machine" "request_workflow" {
  name     = "${local.name_prefix}-request-workflow"
  role_arn = aws_iam_role.sfn.arn

  definition = <<EOF
{
  "Comment": "A workflow for FleetOps requests",
  "StartAt": "Open",
  "States": {
    "Open": {
      "Type": "Pass",
      "Result": "OPEN",
      "Next": "PendingApproval"
    },
    "PendingApproval": {
      "Type": "Pass",
      "Result": "PENDING_APPROVAL",
      "Next": "Approved"
    },
    "Approved": {
      "Type": "Pass",
      "Result": "APPROVED",
      "Next": "Assigned"
    },
    "Assigned": {
      "Type": "Pass",
      "Result": "ASSIGNED",
      "Next": "InProgress"
    },
    "InProgress": {
      "Type": "Pass",
      "Result": "IN_PROGRESS",
      "Next": "Completed"
    },
    "Completed": {
      "Type": "Succeed"
    }
  }
}
EOF

  tags = local.common_tags
}




