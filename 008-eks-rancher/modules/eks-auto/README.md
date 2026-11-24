# EKS Auto Mode Module

## Overview

This module deploys an Amazon EKS cluster with **EKS Auto Mode** enabled. AWS manages worker node provisioning, scaling, OS patching, networking, and block storage automatically through built-in Karpenter compute (`general-purpose` and `system` node pools), removing the need for EC2 Auto Scaling Groups or Launch Templates.

It also configures an IAM OIDC Identity Provider for the cluster along with a sample IRSA role (`irsa_demo`) to demonstrate zero-secret pod access to AWS APIs, and supports optional extra admin principals via EKS API access entries.

## Requirements

| Name | Version |
| :--- | :--- |
| terraform | `>= 1.5.0` |
| aws | `~> 6.0` |
| tls | `>= 4.0` |

## Usage

```hcl
module "eks" {
  source = "../modules/eks-auto"

  cluster_name       = "workload-eks"
  kubernetes_version = "1.36"
  subnet_ids         = module.vpc.private_subnet_ids
  environment        = "dev"
}
```

## Inputs

| Name | Description | Type | Default | Required |
| :--- | :--- | :--- | :--- | :--- |
| `cluster_name` | Name of the EKS Auto Mode cluster | `string` | n/a | yes |
| `kubernetes_version` | Kubernetes control plane version | `string` | `"1.36"` | no |
| `subnet_ids` | List of private subnet IDs across at least 2 Availability Zones | `list(string)` | n/a | yes |
| `endpoint_public_access` | Whether the EKS Kubernetes API server is reachable over the internet | `bool` | `true` | no |
| `admin_principal_arns` | Optional extra IAM user or role ARNs granted cluster-admin permissions | `list(string)` | `[]` | no |
| `environment` | Deployment environment name | `string` | `"dev"` | no |

## Outputs

| Name | Description |
| :--- | :--- |
| `cluster_name` | Name of the EKS cluster |
| `cluster_arn` | ARN of the EKS cluster |
| `cluster_endpoint` | Endpoint URL for the Kubernetes API server |
| `cluster_ca_certificate` | Base64-encoded certificate authority data for the cluster |
| `oidc_provider_arn` | ARN of the IAM OIDC provider for IRSA |
| `oidc_provider_url` | Issuer URL for the cluster OIDC provider |
| `irsa_demo_role_arn` | ARN of the demo IRSA IAM role |
| `node_role_arn` | ARN of the Auto Mode worker node IAM role |
