variable "aws_region" {
  description = "AWS region where the clusters are deployed"
  type        = string
}

variable "environment" {
  description = "Deployment environment name (must match clusters stack)"
  type        = string
}

variable "workload_cluster_name" {
  description = "Name of the target workload EKS cluster to import into Rancher"
  type        = string
}
