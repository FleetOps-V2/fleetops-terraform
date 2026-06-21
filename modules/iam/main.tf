# =============================================================
# Module: iam  |  Phase: 2A
# Provisions: EKS Node Role, App IRSA Role, Lambda Role
# No static access keys — all roles assumed via instance profile
# or OIDC federation (IRSA)
# =============================================================

data "aws_caller_identity" "current" {}

locals {
  name_prefix = "fleetops-${var.environment}"
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "FleetOps"
    Owner       = "FleetOps-Team"
  }
}
# ── EKS Node Role ─────────────────────────────────────────────
# Assumed by EC2 instances in the EKS Managed Node Group
resource "aws_iam_role" "eks_node" {
  name = "${local.name_prefix}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

# AWS managed policies required for EKS nodes
resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_readonly" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_ssm" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "eks_node" {
  name = "${local.name_prefix}-eks-node-profile"
  role = aws_iam_role.eks_node.name
  tags = local.common_tags
}

# ECR pull-through cache: nodes must be able to create cached repos and
# import upstream images on first pull. ReadOnly policy does not cover these.
resource "aws_iam_role_policy" "eks_node_ecr_pull_through" {
  name = "${local.name_prefix}-eks-node-ecr-pull-through"
  role = aws_iam_role.eks_node.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ecr:CreateRepository", "ecr:BatchImportUpstreamImage"]
      Resource = "arn:aws:ecr:*:*:repository/*"
    }]
  })
}

# ── App IRSA Role ─────────────────────────────────────────────
# Assumed by Kubernetes ServiceAccounts via OIDC federation
# Grants: Secrets Manager read, SSM read, KMS decrypt, S3 access
resource "aws_iam_role" "app_service_account" {
  name = "${local.name_prefix}-app-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider_url}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account_name}"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "app_secrets" {
  name = "${local.name_prefix}-app-secrets-policy"
  role = aws_iam_role.app_service_account.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project}/*"
      },
      {
        Sid    = "SSMParameterRead"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project}/*"
      },
      {
        Sid    = "KMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arns
      },
      {
        Sid    = "S3VehicleDocuments"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project}-${var.environment}-vehicle-docs",
          "arn:aws:s3:::${var.project}-${var.environment}-vehicle-docs/*"
        ]
      },
      {
        Sid      = "BedrockInvoke"
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
        Resource = "arn:aws:bedrock:${var.aws_region}::foundation-model/*"
      },
      {
        Sid    = "EventDrivenPublishing"
        Effect = "Allow"
        Action = ["sns:Publish", "sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage"]
        Resource = [
          var.sns_alerts_topic_arn != "" ? var.sns_alerts_topic_arn : "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.project}-*",
          var.sqs_gps_queue_arn != "" ? var.sqs_gps_queue_arn : "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.project}-*"
        ]
      },
      {
        Sid      = "CloudWatchAuditLogs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/fleetops/*:*"
      },
      {
        Sid      = "DynamoDBAccess"
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:Query", "dynamodb:Scan", "dynamodb:UpdateItem"]
        Resource = var.dynamodb_telemetry_arn != "" ? var.dynamodb_telemetry_arn : "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.project}-*"
      }
    ]
  })
}

# ── Lambda Execution Role ─────────────────────────────────────
resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ── AWS DevOps Agent Role ─────────────────────────────────────
# Assumed by the AWS DevOps Agent service to read FleetOps infrastructure.
# Role ARN is entered in the Agent Space console configuration.
resource "aws_iam_role" "devops_agent" {
  name = "${local.name_prefix}-devops-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "aidevops.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "devops_agent_cloudwatch" {
  role       = aws_iam_role.devops_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "devops_agent_eks" {
  role       = aws_iam_role.devops_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "devops_agent_rds" {
  role       = aws_iam_role.devops_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
}

resource "aws_iam_role_policy" "lambda_app" {
  name = "${local.name_prefix}-lambda-app-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "SNSPublish"
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.project}-*"
      },
      {
        Sid      = "SQSSend"
        Effect   = "Allow"
        Action   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.project}-*"
      },
      {
        Sid      = "SecretsRead"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project}/*"
      }
    ]
  })
}




