terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "fleetops-terraform-state-johan"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "fleetops-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "security" {
  source             = "../../modules/security"
  environment        = var.environment
  aws_region         = var.aws_region
  bedrock_access_key = var.bedrock_access_key
  bedrock_secret_key = var.bedrock_secret_key
}




