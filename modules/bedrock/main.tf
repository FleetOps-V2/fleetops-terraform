locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "bedrock"
    Owner       = "FleetOps-Team"
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Deployed in Account B (Bedrock account).
# Trusted by the IRSA role in Account A (EKS account) via sts:AssumeRole.
resource "aws_iam_role" "bedrock_invoke" {
  name        = "${local.name_prefix}-bedrock-invoke-role"
  description = "Assumed by FleetOps app IRSA role in Account A to invoke Bedrock cross-account"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = var.eks_account_app_role_arn
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "bedrock_invoke" {
  name = "${local.name_prefix}-bedrock-invoke-policy"
  role = aws_iam_role.bedrock_invoke.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "BedrockModelInvoke"
      Effect = "Allow"
      Action = [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ]
      Resource = "*"
    }]
  })
}
