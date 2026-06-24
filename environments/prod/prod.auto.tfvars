environment = "prod"
aws_region  = "us-east-1"
domain_name = "fleetops.website"

vpc_cidr             = "10.2.0.0/16"
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
private_subnet_cidrs = ["10.2.10.0/24", "10.2.11.0/24"]
db_subnet_cidrs      = ["10.2.20.0/24", "10.2.21.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

db_instance_class          = "db.t3.micro"
enable_deletion_protection = false

redis_node_type = "cache.t3.micro"

eks_cluster_version    = "1.31"
eks_node_instance_type = "m7i-flex.large"
eks_node_min_size      = 2
eks_node_max_size      = 5
eks_node_desired_size  = 2

k8s_namespace            = "fleetops-prod"
k8s_service_account_name = "fleetops-app"

argocd_repo_url = "https://github.com/FleetOps-V2/fleetops-deployments.git"

vehicle_service_url = "https://origin.fleetops.website"
auth_service_url    = "https://origin.fleetops.website"

admin_iam_user_arns = [
  "arn:aws:iam::538661800892:user/fleetops-terraform-deployer",
  "arn:aws:iam::538661800892:role/fleetops-prod-github-actions-role",
]

bedrock_invoke_role_arn = "arn:aws:iam::612524168263:role/fleetops-prod-bedrock-invoke-role"

alert_emails   = ["johannabyvannilam@gmail.com"]
alb_arn_suffix = "app/k8s-fleetops-69397799c8/4cfc8327e7d8ede3"
