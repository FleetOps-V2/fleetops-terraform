output "vpc_id"                   { value = module.networking.vpc_id }
output "private_subnet_ids"       { value = module.networking.private_subnet_ids }
output "public_subnet_ids"        { value = module.networking.public_subnet_ids }
output "ecr_repository_urls" {
  description = "ECR repository URLs — repos live in bootstrap, computed here for convenience"
  value = {
    for svc in ["auth-service", "vehicle-service", "request-service", "maintenance-service", "frontend"] :
    svc => "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/fleetops-dev/${svc}"
  }
}
output "rds_endpoint"             { value = module.rds.db_endpoint }
output "redis_endpoint"           { value = module.redis.redis_endpoint }
output "s3_vehicle_docs_bucket"   { value = module.s3.vehicle_docs_bucket_name }
output "efs_id"                   { value = module.efs.efs_id }
output "efs_dns_name"             { value = module.efs.efs_dns_name }
output "db_secret_arn"            { value = module.secrets_manager.db_secret_arn }
output "jwt_secret_arn"           { value = module.secrets_manager.jwt_secret_arn }
output "route53_name_servers"     { value = module.route53.name_servers }
output "eks_node_role_arn"        { value = module.iam.eks_node_role_arn }
output "app_irsa_role_arn"        { value = module.iam.app_irsa_role_arn }

output "kms_rds_key_arn"          { value = module.kms.rds_key_arn }
output "kms_secrets_key_arn"      { value = module.kms.secrets_key_arn }
output "kms_s3_key_arn"           { value = module.kms.s3_key_arn }

# Ingress bootstrap outputs — consumed by GitHub Actions to generate charts/ingress/values-infra.yaml
output "acm_certificate_arn"      { value = module.acm.certificate_arn }
output "alb_sg_id"                { value = module.networking.alb_sg_id }
output "hosted_zone_id"           { value = module.route53.zone_id }
output "eks_cluster_name"         { value = module.eks_cluster.cluster_name }
output "eks_cluster_endpoint"     { value = module.eks_cluster.cluster_endpoint }
output "github_actions_role_arn"  { value = module.iam.github_actions_role_arn }




output "github_actions_ecr_role_arn" { value = module.iam.github_actions_ecr_role_arn }
output "devops_agent_role_arn"      { value = module.iam.devops_agent_role_arn }
