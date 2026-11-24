variable "cluster_name" {
  description = "Name of the EKS Auto Mode cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes control plane version"
  type        = string
  default     = "1.36"
}

variable "subnet_ids" {
  description = "List of private subnet IDs across at least 2 Availability Zones"
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Whether the EKS Kubernetes API server is reachable over the internet"
  type        = bool
  default     = true
}

variable "admin_principal_arns" {
  description = "Optional extra IAM user or role ARNs granted cluster-admin permissions"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}
