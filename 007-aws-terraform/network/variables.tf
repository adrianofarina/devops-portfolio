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

# AWS Budgets Financial Governance Variables
variable "monthly_budget_limit" {
  description = "Monthly spending limit in USD for AWS Budgets alerts"
  type        = string
  default     = "5.0"
}

variable "budget_email" {
  description = "Email address for AWS Budgets threshold alert notifications (leave empty to skip budget creation)"
  type        = string
  default     = ""
}
