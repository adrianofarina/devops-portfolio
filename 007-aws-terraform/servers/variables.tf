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
