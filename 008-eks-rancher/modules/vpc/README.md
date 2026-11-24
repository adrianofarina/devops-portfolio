# VPC Module (EKS Multi-AZ)

## Overview

This module builds a Multi-AZ AWS VPC network foundation ready for Amazon EKS. It provisions 2 public subnets and 2 private subnets across two Availability Zones, attaches an Internet Gateway, and routes private subnet outbound traffic through a single shared NAT Gateway to keep lab costs low.

It also adds the AWS discovery tags (`kubernetes.io/role/elb` and `kubernetes.io/role/internal-elb`) required by EKS Auto Mode to automatically provision internet-facing and internal load balancers. See the official AWS documentation for full subnet tagging details:
* [AWS EKS Network Load Balancing Subnet Tags](https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html)
* [AWS EKS Application Load Balancing on EKS](https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html)

## Requirements

| Name | Version |
| :--- | :--- |
| terraform | `>= 1.5.0` |
| aws | `>= 5.0` |

## Usage

```hcl
module "vpc" {
  source = "../modules/vpc"

  vpc_cidr              = "172.16.0.0/16"
  public_subnet_1_cidr  = "172.16.1.0/24"
  public_subnet_2_cidr  = "172.16.2.0/24"
  private_subnet_1_cidr = "172.16.10.0/24"
  private_subnet_2_cidr = "172.16.20.0/24"
  az1                   = "us-east-1a"
  az2                   = "us-east-1b"
  cluster_name          = "mgmt-eks"
  environment           = "dev"
}
```

## Inputs

| Name | Description | Type | Default | Required |
| :--- | :--- | :--- | :--- | :--- |
| `vpc_cidr` | Base CIDR block for the VPC | `string` | n/a | yes |
| `public_subnet_1_cidr` | CIDR block for the first public subnet (AZ 1) | `string` | n/a | yes |
| `public_subnet_2_cidr` | CIDR block for the second public subnet (AZ 2) | `string` | n/a | yes |
| `private_subnet_1_cidr` | CIDR block for the first private subnet for EKS nodes (AZ 1) | `string` | n/a | yes |
| `private_subnet_2_cidr` | CIDR block for the second private subnet for EKS nodes (AZ 2) | `string` | n/a | yes |
| `az1` | Primary AWS Availability Zone | `string` | n/a | yes |
| `az2` | Secondary AWS Availability Zone (required by EKS) | `string` | n/a | yes |
| `cluster_name` | EKS cluster name used for required AWS subnet discovery tags | `string` | n/a | yes |
| `environment` | Deployment environment name | `string` | n/a | yes |

## Outputs

| Name | Description |
| :--- | :--- |
| `vpc_id` | ID of the VPC |
| `vpc_cidr` | CIDR block of the VPC |
| `public_subnet_ids` | List of public subnet IDs across both AZs |
| `private_subnet_ids` | List of private subnet IDs across both AZs |
| `nat_gateway_public_ip` | Elastic IP attached to the NAT Gateway |
