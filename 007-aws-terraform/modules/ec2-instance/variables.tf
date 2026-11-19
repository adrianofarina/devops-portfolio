variable "name" {
  description = "Name prefix for compute resources"
  type        = string
}

variable "vpc_id" {
  description = "Target VPC ID for security group creation"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where compute workloads can be launched"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance sizing"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Optional explicit AMI ID override. Defaults to latest Amazon Linux 2023"
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "Optional IAM instance profile name for AWS Systems Manager (SSM)"
  type        = string
  default     = null
}

variable "app_port" {
  description = "Inbound application port"
  type        = number
  default     = 8080
}

variable "allowed_ingress_cidrs" {
  description = "CIDR blocks permitted to access the application port"
  type        = list(string)
  default     = ["172.16.1.0/24"]
}

variable "allowed_security_group_ids" {
  description = "List of Security Group IDs permitted to access the application port (e.g. ALB security group)"
  type        = list(string)
  default     = []
}

variable "target_group_arns" {
  description = "List of Target Group ARNs to attach the Auto Scaling Group instances to"
  type        = list(string)
  default     = []
}

variable "custom_user_data" {
  description = "Optional raw user data script. Overrides the default template if provided"
  type        = string
  default     = null
}

variable "enable_autoscaling" {
  description = "If true, deploy via Auto Scaling Group and Launch Template. If false, deploy standalone instance"
  type        = bool
  default     = true
}

variable "asg_min_size" {
  description = "Minimum instance count for Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum instance count for Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Desired instance count for Auto Scaling Group"
  type        = number
  default     = 1
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}
