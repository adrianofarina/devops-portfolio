# Rancher Platform Module

## Overview

This module deploys the Rancher Manager control plane onto the management EKS Auto Mode cluster. It handles everything needed to expose Rancher over HTTPS without buying a custom domain:

1. Generates a wildcard self-signed certificate (`*.<region>.elb.amazonaws.com`) and imports it into AWS Certificate Manager (ACM).
2. Deploys the native EKS Auto Mode `IngressClass` (`alb`) via a lightweight local Helm chart.
3. Installs `cert-manager` via Helm for internal cluster TLS signing.
4. Installs `rancher` via Helm with explicit CPU/memory requests so EKS Auto Mode provisions the required node capacity.
5. Creates an internet-facing AWS Application Load Balancer (ALB) Ingress routing port 443 directly to Rancher.

## Requirements

| Name | Version |
| :--- | :--- |
| terraform | `>= 1.5.0` |
| aws | `~> 6.0` |
| helm | `~> 3.0` |
| kubernetes | `~> 2.35` |
| tls | `>= 4.0` |

## Usage

```hcl
module "rancher" {
  source = "../modules/rancher"

  aws_region                 = "us-east-1"
  environment                = "dev"
  rancher_hostname           = "rancher.internal"
  rancher_bootstrap_password = var.rancher_bootstrap_password
  rancher_replicas           = 1
  cert_manager_version       = "v1.21.3"
}
```

## Inputs

| Name | Description | Type | Default | Required |
| :--- | :--- | :--- | :--- | :--- |
| `aws_region` | AWS region used for the wildcard ELB self-signed certificate | `string` | n/a | yes |
| `environment` | Deployment environment name | `string` | n/a | yes |
| `rancher_hostname` | Internal placeholder hostname passed to Rancher Helm chart | `string` | n/a | yes |
| `rancher_bootstrap_password` | Initial bootstrap password for Rancher admin login | `string` | n/a | yes |
| `rancher_replicas` | Number of Rancher manager pods (keep at 1 for lab cost savings) | `number` | n/a | yes |
| `cert_manager_version` | Helm chart version for cert-manager | `string` | n/a | yes |

## Outputs

| Name | Description |
| :--- | :--- |
| `rancher_alb_hostname` | Public DNS hostname of the AWS Application Load Balancer for Rancher |
| `rancher_url` | HTTPS URL to access Rancher Manager UI and REST API |
| `acm_certificate_arn` | ARN of the self-signed certificate imported into AWS ACM |

## References

* [cert-manager Docs: Installing with Helm](https://cert-manager.io/docs/installation/helm/)
* [Rancher Docs: Install/Upgrade Rancher on a Kubernetes Cluster (Helm + cert-manager)](https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/install-upgrade-on-a-kubernetes-cluster)
* [AWS Docs: Configure Application Load Balancers with EKS Auto Mode](https://docs.aws.amazon.com/eks/latest/userguide/auto-configure-alb.html)
