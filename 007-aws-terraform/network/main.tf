# Network Foundation setup

# Discover available Availability Zones in the specified region
data "aws_availability_zones" "available" {
  state = "available"
}

# 1. VPC setup
module "vpc" {
  source = "../modules/vpc"

  # Base VPC CIDR
  vpc_cidr = "172.16.0.0/16"

  # 3-Tier Subnet CIDR Allocations
  public_subnet_cidr  = "172.16.1.0/24"
  private_subnet_cidr = "172.16.2.0/24"
  secure_subnet_cidr  = "172.16.3.0/24"

  # Availability Zone & Environment
  availability_zone = data.aws_availability_zones.available.names[0]
  environment       = var.environment
}
