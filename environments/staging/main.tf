terraform {
  backend "s3" {
    bucket         = "fleetops-terraform-state-johan"
    key            = "environments/staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "fleetops-terraform-locks"
    encrypt        = true
  }
}

module "security" {
  source      = "../../modules/security"
  environment = var.environment
  aws_region  = var.aws_region
}

module "networking" {
  source      = "../../modules/networking"
  environment = var.environment
  aws_region  = var.aws_region
  vpc_cidr    = var.vpc_cidr
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "fleetops"
      Environment = "staging"
      ManagedBy   = "terraform"
      Owner       = "FleetOps-Team"
    }
  }
}




