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

resource "aws_cloudwatch_log_group" "sfn_logs" {
  name              = "/aws/states/${local.name_prefix}-request-workflow"
  retention_in_days = 365
  kms_key_id        = var.kms_key_arn
  tags              = local.common_tags
}

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

resource "aws_iam_role_policy" "sfn_logging" {
  #checkov:skip=CKV_AWS_288:CloudWatch log delivery and X-Ray APIs require wildcard resource
  #checkov:skip=CKV_AWS_290:Step Functions logging requires write access to CloudWatch log delivery
  #checkov:skip=CKV_AWS_355:CloudWatch Logs delivery APIs do not support resource-level restrictions
  name = "${local.name_prefix}-sfn-logging"
  role = aws_iam_role.sfn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Sid    = "XRayTracing"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_sfn_state_machine" "request_workflow" {
  name     = "${local.name_prefix}-request-workflow"
  role_arn = aws_iam_role.sfn.arn

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn_logs.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tracing_configuration {
    enabled = true
  }

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

  depends_on = [aws_iam_role_policy.sfn_logging]
}
