terraform {
  backend "s3" {
    bucket         = "fleetops-terraform-state-johan"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "fleetops-terraform-locks"
    encrypt        = true
  }

  required_version = ">= 1.6.0"
  required_providers {
    aws        = { source = "hashicorp/aws",        version = "= 5.100.0" }
    helm       = { source = "hashicorp/helm",       version = "= 2.17.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "= 2.38.0" }
    random     = { source = "hashicorp/random",     version = ">= 3.6.0" }
    tls        = { source = "hashicorp/tls",        version = "= 4.3.0" }
    archive    = { source = "hashicorp/archive",    version = "= 2.8.0" }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "fleetops"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "FleetOps-Team"
    }
  }
}

# ── Phase 2B: Helm + Kubernetes providers ─────────────────────
# Dynamically configured from EKS cluster outputs.
# On first apply (Phase 2A only), these providers will have empty
# endpoints and are harmless — helm_release resources have explicit
# depends_on on the cluster module.
provider "helm" {
  kubernetes {
    host                   = try(module.eks_cluster.cluster_endpoint, "")
    cluster_ca_certificate = try(base64decode(module.eks_cluster.cluster_ca_data), "")
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", try(module.eks_cluster.cluster_name, "")]
    }
  }
}

provider "kubernetes" {
  host                   = try(module.eks_cluster.cluster_endpoint, "")
  cluster_ca_certificate = try(base64decode(module.eks_cluster.cluster_ca_data), "")
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", try(module.eks_cluster.cluster_name, "")]
  }
}

# ── Phase 2A Module Calls ─────────────────────────────────────

data "aws_caller_identity" "current" {}

module "kms" {
  source      = "../../modules/kms"
  project     = "fleetops"
  environment = var.environment
}

module "networking" {
  source               = "../../modules/networking"
  project              = "fleetops"
  environment          = var.environment
  aws_region           = var.aws_region
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "iam" {
  source       = "../../modules/iam"
  project      = "fleetops"
  environment  = var.environment
  aws_region   = var.aws_region
  kms_key_arns = module.kms.all_key_arns

  oidc_provider_url        = module.eks_oidc.oidc_provider_url
  k8s_namespace            = var.k8s_namespace
  k8s_service_account_name = var.k8s_service_account_name

  # Event ARNs for IRSA policies (Phases 4-7)
  dynamodb_telemetry_arn = module.dynamodb.telemetry_table_arn
  sqs_gps_queue_arn      = module.sqs.gps_tracking_queue_arn
  sns_alerts_topic_arn   = module.sns.service_alerts_topic_arn
  bedrock_policy_arn     = module.bedrock.bedrock_access_policy_arn
}

module "rds" {
  source                     = "../../modules/rds"
  project                    = "fleetops"
  environment                = var.environment
  private_subnet_ids         = module.networking.private_subnet_ids
  rds_sg_id                  = module.networking.rds_sg_id
  kms_rds_key_arn            = module.kms.rds_key_arn
  db_instance_class          = var.db_instance_class
  db_username                = var.db_username
  db_password                = var.db_password
  enable_deletion_protection = var.enable_deletion_protection
}

module "redis" {
  source             = "../../modules/redis"
  project            = "fleetops"
  environment        = var.environment
  private_subnet_ids = module.networking.private_subnet_ids
  redis_sg_id        = module.networking.redis_sg_id
  redis_node_type    = var.redis_node_type
}

module "s3" {
  source          = "../../modules/s3"
  project         = "fleetops"
  environment     = var.environment
  kms_s3_key_arn  = module.kms.s3_key_arn
  frontend_origin = "https://${var.domain_name}"
}

module "efs" {
  source             = "../../modules/efs"
  project            = "fleetops"
  environment        = var.environment
  private_subnet_ids = module.networking.private_subnet_ids
  efs_sg_id          = module.networking.efs_sg_id
  kms_s3_key_arn     = module.kms.s3_key_arn
}

module "secrets_manager" {
  source              = "../../modules/secrets-manager"
  project             = "fleetops"
  environment         = var.environment
  kms_secrets_key_arn = module.kms.secrets_key_arn
  db_host             = module.rds.db_endpoint
  db_username         = var.db_username
  db_password         = var.db_password
  jwt_secret          = var.jwt_secret
  github_pat          = var.github_pat
}

module "ssm" {
  source                  = "../../modules/ssm"
  project                 = "fleetops"
  environment             = var.environment
  redis_endpoint          = module.redis.redis_endpoint
  cors_allowed_origins    = "https://${var.domain_name}"
  app_base_url            = "https://${var.domain_name}"
  insurance_sns_topic_arn = module.sns.insurance_alerts_topic_arn
  service_sns_topic_arn   = module.sns.service_alerts_topic_arn
}

module "route53" {
  source      = "../../modules/route53"
  project     = "fleetops"
  environment = var.environment
  domain_name = var.domain_name
}

# ── Phase 2B Module Calls ─────────────────────────────────────

module "eks_cluster" {
  source               = "../../modules/eks/cluster"
  project              = "fleetops"
  environment          = var.environment
  eks_cluster_version  = var.eks_cluster_version
  public_subnet_ids    = module.networking.public_subnet_ids
  private_subnet_ids   = module.networking.private_subnet_ids
  control_plane_sg_id  = module.networking.eks_control_plane_sg_id
  admin_iam_user_arns  = []
  public_access_cidrs  = var.eks_public_access_cidrs
  kms_secrets_key_arn  = module.kms.secrets_key_arn
}

module "eks_oidc" {
  source           = "../../modules/eks/oidc"
  project          = "fleetops"
  environment      = var.environment
  oidc_issuer_url  = module.eks_cluster.oidc_issuer_url
}

module "eks_nodegroup" {
  source              = "../../modules/eks/nodegroup"
  project             = "fleetops"
  environment         = var.environment
  cluster_name        = module.eks_cluster.cluster_name
  node_role_arn       = module.iam.eks_node_role_arn
  private_subnet_ids  = module.networking.private_subnet_ids
  node_instance_type  = var.eks_node_instance_type
  min_size            = var.eks_node_min_size
  max_size            = var.eks_node_max_size
  desired_size        = var.eks_node_desired_size
}

# EKS managed nodes get the auto-created cluster SG, not the node group SG.
# These rules let pods reach RDS and Redis through the cluster SG.
resource "aws_vpc_security_group_ingress_rule" "rds_from_eks_cluster_sg" {
  security_group_id            = module.networking.rds_sg_id
  referenced_security_group_id = module.eks_cluster.cluster_sg_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "PostgreSQL from EKS cluster SG (managed node pods)"
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_eks_cluster_sg" {
  security_group_id            = module.networking.redis_sg_id
  referenced_security_group_id = module.eks_cluster.cluster_sg_id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  description                  = "Redis from EKS cluster SG (managed node pods)"
}

# ALB health checks and traffic reach pods on port 8080 (backend) and 80 (frontend).
# The EKS auto-created cluster SG is on all managed nodes; ALB uses target-type=ip.
resource "aws_vpc_security_group_ingress_rule" "alb_to_pods_8080" {
  security_group_id            = module.eks_cluster.cluster_sg_id
  referenced_security_group_id = module.networking.alb_sg_id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  description                  = "ALB to backend pods on 8080 (Spring Boot)"
}

resource "aws_vpc_security_group_ingress_rule" "alb_to_pods_80" {
  #checkov:skip=CKV_AWS_260:Source is scoped to ALB SG via referenced_security_group_id, not 0.0.0.0/0
  security_group_id            = module.eks_cluster.cluster_sg_id
  referenced_security_group_id = module.networking.alb_sg_id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  description                  = "ALB to frontend pods on 80 (nginx)"
}

# CloudFront uses origin.fleetops.website as its origin (https-only).
# The wildcard cert *.fleetops.website covers this subdomain.
# ALB is created by the K8s ALB controller after Ingress is deployed — not managed by Terraform.
# Set var.origin_alb_dns after first K8s deploy, then re-apply to create this record.
resource "aws_route53_record" "origin_alb_alias" {
  #checkov:skip=CKV2_AWS_23:Alias target is the K8s ALB provisioned by the ALB Ingress Controller after first deploy; not trackable by Terraform
  count   = var.origin_alb_dns != "" ? 1 : 0

  zone_id = module.route53.zone_id
  name    = "origin.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.origin_alb_dns
    zone_id                = "Z35SXDOTRQ7X7K"  # us-east-1 ALB hosted zone — fixed by AWS
    evaluate_target_health = true
  }
}

# argocd.fleetops.website — shares the same ALB as origin.fleetops.website
# (both Ingresses use group.name: fleetops, so one ALB handles both).
# Set origin_alb_dns after the first K8s deploy, then re-apply.
resource "aws_route53_record" "argocd" {
  #checkov:skip=CKV2_AWS_23:Alias target is the K8s ALB provisioned by the ALB Ingress Controller after first deploy; not trackable by Terraform
  count   = var.origin_alb_dns != "" ? 1 : 0

  zone_id = module.route53.zone_id
  name    = "argocd.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.origin_alb_dns
    zone_id                = "Z35SXDOTRQ7X7K"
    evaluate_target_health = true
  }
}

module "eks_addons" {
  source               = "../../modules/eks/addons"
  project              = "fleetops"
  environment          = var.environment
  aws_region           = var.aws_region
  cluster_name         = module.eks_cluster.cluster_name
  vpc_id               = module.networking.vpc_id
  oidc_provider_url    = module.eks_oidc.oidc_provider_url
  argocd_repo_url      = var.argocd_repo_url
  kms_secrets_key_arn  = module.kms.secrets_key_arn
  acm_certificate_arn  = module.acm.certificate_arn
  alb_sg_id            = module.networking.alb_sg_id
  domain_name          = var.domain_name

  # Helm charts need schedulable nodes — wait for node group to be ready.
  # secrets_manager dependency ensures GitHub PAT secret exists before eks_addons tries to read it.
  depends_on = [module.eks_nodegroup, module.secrets_manager]
}

# ── Phases 4-7 Module Calls ──────────────────────────────────

module "sns" {
  source          = "../../modules/sns"
  project         = "fleetops"
  environment     = var.environment
  kms_sns_key_arn = module.kms.events_key_arn
}

module "lambda" {
  source                             = "../../modules/lambda"
  project                            = "fleetops"
  environment                        = var.environment
  lambda_role_arn                    = module.iam.lambda_role_arn
  vehicle_service_url                = var.vehicle_service_url
  auth_service_url                   = var.auth_service_url
  lambda_service_credentials_secret_arn = module.secrets_manager.lambda_service_credentials_arn
  insurance_sns_arn                  = module.sns.insurance_alerts_topic_arn
  service_sns_arn                    = module.sns.service_alerts_topic_arn
}

module "eventbridge" {
  source                      = "../../modules/eventbridge"
  project                     = "fleetops"
  environment                 = var.environment
  alert_processor_lambda_arn  = module.lambda.alert_processor_function_arn
  alert_processor_lambda_name = module.lambda.alert_processor_function_name
}

module "dynamodb" {
  source             = "../../modules/dynamodb"
  project            = "fleetops"
  environment        = var.environment
  kms_events_key_arn = module.kms.events_key_arn
}

module "sqs" {
  source             = "../../modules/sqs"
  project            = "fleetops"
  environment        = var.environment
  kms_events_key_arn = module.kms.events_key_arn
}

module "step_functions" {
  source      = "../../modules/step-functions"
  project     = "fleetops"
  environment = var.environment
  kms_key_arn = module.kms.events_key_arn
}

module "cloudwatch" {
  source                   = "../../modules/cloudwatch"
  project                  = "fleetops"
  environment              = var.environment
  service_alerts_topic_arn = module.sns.service_alerts_topic_arn
  rds_instance_identifier  = module.rds.db_identifier
  kms_key_arn              = module.kms.events_key_arn
}

module "cloudtrail" {
  source      = "../../modules/cloudtrail"
  project     = "fleetops"
  environment = var.environment
  kms_key_arn = module.kms.events_key_arn
}

module "waf" {
  source      = "../../modules/waf"
  project     = "fleetops"
  environment = var.environment
}

module "config_aws" {
  source      = "../../modules/config"
  project     = "fleetops"
  environment = var.environment
}

module "bedrock" {
  source      = "../../modules/bedrock"
  project     = "fleetops"
  environment = var.environment
}

module "acm" {
  source         = "../../modules/acm"
  project        = "fleetops"
  environment    = var.environment
  domain_name    = var.domain_name
  hosted_zone_id = module.route53.zone_id
}

module "cloudfront" {
  source              = "../../modules/cloudfront"
  project             = "fleetops"
  environment         = var.environment
  domain_name         = var.domain_name
  acm_certificate_arn = module.acm.certificate_arn
  waf_web_acl_arn     = module.waf.web_acl_arn
  hosted_zone_id      = module.route53.zone_id
}

# ── Prod-namespace secrets ─────────────────────────────────────
# This cluster hosts both fleetops-dev and fleetops-prod K8s namespaces.
# The prod namespace ExternalSecrets reference fleetops/prod/* paths.
# These resources create those paths pointing to the same infrastructure.

resource "random_password" "lambda_service_prod_ns" {
  length           = 24
  special          = true
  override_special = "!#$%&*-_=+"
}

resource "aws_secretsmanager_secret" "db_prod_ns" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation requires a rotation Lambda; managed manually for this project
  name                    = "fleetops/prod/db"
  description             = "FleetOps prod-namespace DB credentials (same RDS as dev)"
  kms_key_id              = module.kms.secrets_key_arn
  recovery_window_in_days = 0

  tags = { Name = "fleetops-prod-ns-db-secret", ManagedBy = "terraform" }
}

resource "aws_secretsmanager_secret_version" "db_prod_ns" {
  secret_id = aws_secretsmanager_secret.db_prod_ns.id
  secret_string = jsonencode({
    host     = module.rds.db_endpoint
    port     = 5432
    dbname   = "postgres"
    username = var.db_username
    password = var.db_password
  })
}

resource "aws_secretsmanager_secret" "jwt_prod_ns" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation requires a rotation Lambda; managed manually for this project
  name                    = "fleetops/prod/jwt"
  description             = "FleetOps prod-namespace JWT secret (same as dev)"
  kms_key_id              = module.kms.secrets_key_arn
  recovery_window_in_days = 0

  tags = { Name = "fleetops-prod-ns-jwt-secret", ManagedBy = "terraform" }
}

resource "aws_secretsmanager_secret_version" "jwt_prod_ns" {
  secret_id     = aws_secretsmanager_secret.jwt_prod_ns.id
  secret_string = jsonencode({ jwt_secret = var.jwt_secret })
}

resource "aws_secretsmanager_secret" "lambda_service_prod_ns" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation requires a rotation Lambda; managed manually for this project
  name                    = "fleetops/prod/lambda-service-credentials"
  description             = "Credentials for lambda-service account in prod namespace"
  kms_key_id              = module.kms.secrets_key_arn
  recovery_window_in_days = 0

  tags = { Name = "fleetops-prod-ns-lambda-svc-secret", ManagedBy = "terraform" }
}

resource "aws_secretsmanager_secret_version" "lambda_service_prod_ns" {
  secret_id = aws_secretsmanager_secret.lambda_service_prod_ns.id
  secret_string = jsonencode({
    username = "lambda-service"
    password = random_password.lambda_service_prod_ns.result
  })
}

resource "aws_ssm_parameter" "redis_endpoint_prod_ns" {
  #checkov:skip=CKV2_AWS_34:Non-sensitive endpoint
  name        = "/fleetops/prod/redis/endpoint"
  description = "Redis endpoint for prod namespace (same cluster as dev)"
  type        = "String"
  value       = module.redis.redis_endpoint

  tags = { Name = "fleetops-prod-ns-redis-endpoint", ManagedBy = "terraform" }
}

resource "aws_ssm_parameter" "insurance_sns_prod_ns" {
  #checkov:skip=CKV2_AWS_34:SNS topic ARN is a resource identifier, not a secret
  name        = "/fleetops/prod/sns/insurance-alerts-arn"
  description = "Insurance SNS ARN for prod namespace"
  type        = "String"
  value       = module.sns.insurance_alerts_topic_arn

  tags = { Name = "fleetops-prod-ns-insurance-sns", ManagedBy = "terraform" }
}

resource "aws_ssm_parameter" "service_sns_prod_ns" {
  #checkov:skip=CKV2_AWS_34:SNS topic ARN is a resource identifier, not a secret
  name        = "/fleetops/prod/sns/service-alerts-arn"
  description = "Service SNS ARN for prod namespace"
  type        = "String"
  value       = module.sns.service_alerts_topic_arn

  tags = { Name = "fleetops-prod-ns-service-sns", ManagedBy = "terraform" }
}

