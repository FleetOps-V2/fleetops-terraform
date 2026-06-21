# =============================================================
# Module: route53  |  Phase: 2A
# Hosted Zone for fleetops.website
# NS records must be manually added to GoDaddy after apply
# ALB alias record created in Phase 2B once ALB DNS is known
# =============================================================

locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "route53"
    Owner       = "FleetOps-Team"
  }
}

# Hosted Zone — delegates DNS to AWS Route53 name servers
resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "FleetOps ${var.environment} hosted zone — managed by Terraform"
  tags    = merge(local.common_tags, { Name = "${local.name_prefix}-zone" })
}

# ALB Alias Record — points domain root to the ALB (created in Phase 2B)
# Uncomment once ALB DNS name is available from EKS/ALB controller
# resource "aws_route53_record" "alb_alias" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = var.domain_name
#   type    = "A"
#   alias {
#     name                   = var.alb_dns_name
#     zone_id                = var.alb_zone_id
#     evaluate_target_health = true
#   }
# }




