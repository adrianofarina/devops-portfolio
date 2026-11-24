variable "aws_region" {
  description = "AWS region to deploy the clusters"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}

variable "mgmt_cluster_name" {
  description = "Name for the Rancher management EKS Auto Mode cluster"
  type        = string
  default     = "mgmt-eks"
}

variable "workload_cluster_name" {
  description = "Name for the target workload EKS Auto Mode cluster"
  type        = string
  default     = "workload-eks"
}

variable "rancher_bootstrap_password" {
  description = "Initial admin password for Rancher UI and API onboarding"
  type        = string
  sensitive   = true
}

variable "deploy_test_workload" {
  description = "Whether to deploy the test Nginx app + ALB Ingress on workload-eks"
  type        = bool
  default     = true
}

variable "budget_email" {
  description = "Email address for AWS Budget alerts (leave empty to skip)"
  type        = string
  default     = ""
}

variable "monthly_budget_limit" {
  description = "Monthly USD spend alert threshold"
  type        = string
  default     = "5.0"
}
