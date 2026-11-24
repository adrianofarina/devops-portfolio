terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devops-portfolio"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "008-eks-rancher"
      Layer       = "clusters"
    }
  }
}

# Default Kubernetes & Helm providers pointing to the Management EKS cluster
provider "kubernetes" {
  host                   = module.mgmt_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.mgmt_eks.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.mgmt_eks.cluster_name, "--region", var.aws_region]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.mgmt_eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.mgmt_eks.cluster_ca_certificate)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.mgmt_eks.cluster_name, "--region", var.aws_region]
    }
  }
}

# Aliased Kubernetes & Helm providers pointing to the Target Workload EKS cluster
provider "kubernetes" {
  alias                  = "workload"
  host                   = module.workload_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.workload_eks.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.workload_eks.cluster_name, "--region", var.aws_region]
  }
}

provider "helm" {
  alias = "workload"

  kubernetes = {
    host                   = module.workload_eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.workload_eks.cluster_ca_certificate)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.workload_eks.cluster_name, "--region", var.aws_region]
    }
  }
}
