# =============================================================
# Outputs: networking module
# All consuming modules (rds, redis, eks, etc.) reference these
# =============================================================

output "vpc_id" {
  description = "ID of the FleetOps VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (for ALB)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (for EKS nodes, RDS, Redis)"
  value       = aws_subnet.private[*].id
}

output "alb_sg_id" {
  description = "Security group ID for the ALB"
  value       = aws_security_group.alb.id
}

output "eks_nodes_sg_id" {
  description = "Security group ID for EKS worker nodes"
  value       = aws_security_group.eks_nodes.id
}

output "eks_control_plane_sg_id" {
  description = "Security group ID for EKS control plane"
  value       = aws_security_group.eks_control_plane.id
}

output "rds_sg_id" {
  description = "Security group ID for RDS (allows access from EKS nodes only)"
  value       = aws_security_group.rds.id
}

output "redis_sg_id" {
  description = "Security group ID for Redis (allows access from EKS nodes only)"
  value       = aws_security_group.redis.id
}

output "vpc_endpoints_sg_id" {
  description = "Security group ID shared by all VPC Interface Endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

output "efs_sg_id" {
  description = "Security group ID for EFS (allows NFS from EKS nodes)"
  value       = aws_security_group.efs.id
}




