terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devops-portfolio"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "007-aws-terraform"
      Layer       = "servers"
    }
  }
}
