# =============================================================
# Module: efs  |  Phase: 2A
# Shared elastic file system for inspection/damage photos
# and proof-of-delivery files — mounted into EKS pods via CSI
# =============================================================

locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "efs"
    Owner       = "FleetOps-Team"
  }
}

resource "aws_efs_file_system" "main" {
  creation_token   = "${local.name_prefix}-efs"
  encrypted        = true
  kms_key_id       = var.kms_s3_key_arn # Reuse the S3/documents CMK
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS" # Move cold files to Infrequent Access
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-efs" })
}

# Mount target in each private subnet — one per AZ
resource "aws_efs_mount_target" "main" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [var.efs_sg_id]
}

# Access point — scoped path for FleetOps pod writes
resource "aws_efs_access_point" "fleetops" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    uid = 1000
    gid = 1000
  }
  root_directory {
    path = "/fleetops"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "755"
    }
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-efs-ap" })
}





