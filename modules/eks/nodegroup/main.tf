# =============================================================
# Module: eks/nodegroup  |  Phase: 2B
# Managed Node Group — t3.small, private subnets only
# =============================================================

locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project = var.project
    Environment = var.environment
    ManagedBy = "terraform"
    Module = "eks/nodegroup"
    Owner       = "FleetOps-Team"
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = var.cluster_name
  node_group_name = "${local.name_prefix}-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids   # nodes stay private

  instance_types = [var.node_instance_type]
  capacity_type  = "ON_DEMAND"               # not Spot — stable for review

  scaling_config {
    min_size     = var.min_size
    max_size     = var.max_size
    desired_size = var.desired_size
  }

  update_config {
    max_unavailable = 1
  }

  # Amazon Linux 2023 — AL2 reached EoL June 2025
  ami_type = "AL2023_x86_64_STANDARD"

  labels = {
    role        = "application"
    environment = var.environment
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-node-group"
    # Required by Cluster Autoscaler
    "k8s.io/cluster-autoscaler/enabled"                 = "true"
    "k8s.io/cluster-autoscaler/${var.cluster_name}"     = "owned"
  })

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}




