# Lambda Importer Module

## Overview

This module deploys an AWS Lambda function (`python3.12` on `arm64`) that automatically imports a target EKS workload cluster into Rancher via its REST API.

It builds a deployment package bundling `PyYAML` with `src/importer.py`, sets up a least-privilege IAM role (CloudWatch Logs, SSM Parameter Store read, `eks:DescribeCluster`), and creates an EKS Access Entry giving the Lambda permission to apply Rancher's cluster agent manifest directly to `workload-eks` over HTTPS using `boto3` STS bearer tokens.

**Note:** The Python script (`src/importer.py`) was written with the help of AI to save time on the coding side, keeping the focus on the cloud infrastructure, EKS setup, and Terraform automation rather than writing Python API code from scratch.

## Requirements

| Name | Version |
| :--- | :--- |
| terraform | `>= 1.5.0` |
| aws | `~> 6.0` |
| archive | `>= 2.4` |

## Usage

```hcl
module "lambda_importer" {
  source = "../modules/lambda-importer"

  function_name              = "dev-rancher-cluster-importer"
  environment                = "dev"
  workload_cluster_name      = "workload-eks"
  rancher_url_ssm_param      = "/devops-portfolio/dev/rancher/url"
  rancher_password_ssm_param = "/devops-portfolio/dev/rancher/bootstrap-password"
}
```

## Inputs

| Name | Description | Type | Default | Required |
| :--- | :--- | :--- | :--- | :--- |
| `function_name` | Name of the Lambda function that imports the workload cluster into Rancher | `string` | `"rancher-cluster-importer"` | no |
| `environment` | Deployment environment name | `string` | `"dev"` | no |
| `workload_cluster_name` | Name of the target EKS Auto Mode workload cluster to import | `string` | n/a | yes |
| `rancher_url_ssm_param` | SSM Parameter Store name holding the Rancher HTTPS URL | `string` | n/a | yes |
| `rancher_password_ssm_param` | SSM Parameter Store name holding the Rancher admin password | `string` | n/a | yes |

## Outputs

| Name | Description |
| :--- | :--- |
| `lambda_function_name` | Name of the deployed Lambda importer function |
| `lambda_function_arn` | ARN of the Lambda importer function |
| `lambda_role_arn` | ARN of the IAM execution role assumed by the Lambda |

## Packaging & References

AWS Lambda requires Python code and dependencies (`PyYAML`) to be bundled into a `.zip` file. Because the `aws` provider only uploads archives rather than creating them, this module uses `hashicorp/archive` (`data "archive_file"`) to zip the build directory (`src/importer.py` + Linux `arm64` wheels) and generate a `source_code_hash` so Terraform detects code changes automatically.

### Documentation Sources
* [Terraform Registry: archive_file Data Source](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/archive_file)
* [AWS Docs: Deploy Python Lambda functions with .zip file archives](https://docs.aws.amazon.com/lambda/latest/dg/python-package.html)
* [AWS Docs: Grant IAM users access to Kubernetes with EKS access entries](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html)
* [SUSE Rancher Manager Documentation (API & Cluster Registration)](https://ranchermanager.docs.rancher.com/)
* [Official Kubernetes Python Client: create_from_yaml Reference](https://github.com/kubernetes-client/python/blob/master/kubernetes/utils/create_from_yaml.py)
