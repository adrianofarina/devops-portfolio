variable "vpc_cidr" {
  description = "Base CIDR block for the VPC"
  type        = string
  default     = "172.16.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the primary public subnet"
  type        = string
  default     = "172.16.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for the secondary public subnet (for Multi-AZ ALB)"
  type        = string
  default     = "172.16.10.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private application subnet"
  type        = string
  default     = "172.16.2.0/24"
}

variable "secure_subnet_cidr" {
  description = "CIDR block for the secure database subnet"
  type        = string
  default     = "172.16.3.0/24"
}

variable "availability_zone" {
  description = "Primary AWS Availability Zone for subnets"
  type        = string
}

variable "availability_zone_2" {
  description = "Secondary AWS Availability Zone for Multi-AZ public subnets"
  type        = string
  default     = null
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}
