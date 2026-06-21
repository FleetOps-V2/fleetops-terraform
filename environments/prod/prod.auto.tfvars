environment = "prod"
aws_region  = "us-east-1"
domain_name = "fleetops.website"

# Networking
vpc_cidr             = "10.2.0.0/16"
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
private_subnet_cidrs = ["10.2.10.0/24", "10.2.11.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

# Database
db_instance_class          = "db.t3.micro"
enable_deletion_protection = false

# Cache
redis_node_type = "cache.t3.micro"

# EKS
eks_cluster_version    = "1.31"
eks_node_instance_type = "m7i-flex.large"
eks_node_min_size      = 2
eks_node_max_size      = 5
eks_node_desired_size  = 3

# Kubernetes
k8s_namespace            = "fleetops-prod"
k8s_service_account_name = "fleetops-app"

# ArgoCD
argocd_repo_url = "https://github.com/FleetOps-V2/fleetops-deployments.git"

# Lambda service URLs
vehicle_service_url = "http://fleetops-vehicle-service:8080"
auth_service_url    = "http://fleetops-auth-service:8080"

# Set after first K8s deploy — shared ALB created by ALB controller (group: fleetops)
origin_alb_dns = "k8s-fleetops-69397799c8-1893864686.us-east-1.elb.amazonaws.com"

# EKS cluster access — deployer user + GitHub Actions role (needed for Helm provider in CI/CD)
admin_iam_user_arns = [
  "arn:aws:iam::538661800892:user/fleetops-terraform-deployer",
  "arn:aws:iam::538661800892:role/fleetops-prod-github-actions-role",
]
