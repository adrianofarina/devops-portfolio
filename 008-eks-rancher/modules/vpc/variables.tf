variable "vpc_cidr" {
  description = "Base CIDR block for the VPC"
  type        = string
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for the first public subnet (AZ 1)"
  type        = string
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for the second public subnet (AZ 2)"
  type        = string
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for the first private subnet for EKS nodes (AZ 1)"
  type        = string
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for the second private subnet for EKS nodes (AZ 2)"
  type        = string
}

variable "az1" {
  description = "Primary AWS Availability Zone"
  type        = string
}

variable "az2" {
  description = "Secondary AWS Availability Zone (required by EKS)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name used for required AWS subnet discovery tags"
  type        = string
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
}
