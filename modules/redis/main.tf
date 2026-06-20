# =============================================================
# Module: redis  |  Phase: 2A
# cache.t3.micro — Free Tier, single-node ElastiCache
# =============================================================

locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = { Project = var.project
    Environment = var.environment
    ManagedBy = "terraform"
    Module = "redis" }
    Owner       = "FleetOps-Team" }
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.name_prefix}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = local.common_tags
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${local.name_prefix}-redis"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [var.redis_sg_id]

  snapshot_retention_limit = var.environment == "prod" ? 1 : 0
  apply_immediately        = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-redis" })
}




