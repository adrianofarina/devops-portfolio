variable "aws_region" {
  description = "AWS region used for the wildcard ELB self-signed certificate"
  type        = string
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "rancher_hostname" {
  description = "Internal placeholder hostname passed to Rancher Helm chart"
  type        = string
}

variable "rancher_bootstrap_password" {
  description = "Initial bootstrap password for Rancher admin login"
  type        = string
  sensitive   = true
}

variable "rancher_replicas" {
  description = "Number of Rancher manager pods (keep at 1 for lab cost savings)"
  type        = number
}

variable "cert_manager_version" {
  description = "Helm chart version for cert-manager"
  type        = string
}
