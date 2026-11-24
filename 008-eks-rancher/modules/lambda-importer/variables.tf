variable "function_name" {
  description = "Name of the Lambda function that imports the workload cluster into Rancher"
  type        = string
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "workload_cluster_name" {
  description = "Name of the target EKS Auto Mode workload cluster to import"
  type        = string
}

variable "rancher_url_ssm_param" {
  description = "SSM Parameter Store name holding the Rancher HTTPS URL"
  type        = string
}

variable "rancher_password_ssm_param" {
  description = "SSM Parameter Store name holding the Rancher admin password"
  type        = string
}
