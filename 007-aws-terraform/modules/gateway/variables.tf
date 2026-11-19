variable "name" {
  description = "Name prefix for the gateway (ALB) and associated resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the gateway security group and target group are created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs (at least 2 in distinct AZs required by AWS ALB)"
  type        = list(string)
}

variable "backend_port" {
  description = "Application port of backend compute targets"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "HTTP health check request path"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "healthy_threshold" {
  description = "Consecutive successful health checks before marking healthy"
  type        = number
  default     = 2
}

variable "unhealthy_threshold" {
  description = "Consecutive failed health checks before marking unhealthy"
  type        = number
  default     = 3
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}
