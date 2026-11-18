variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Target deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "Base CIDR block for the VPC (RFC 1918 Class B)"
  type        = string
  default     = "172.16.0.0/16"
}
