# Module 008: AWS EKS Auto Mode & Rancher Multi-Cluster Governance

## Overview

In the earlier modules (001 to 006), I focused on core Kubernetes concepts, Helm packaging, and GitOps workflows running locally on KinD. In Module 007, I moved to AWS to build out foundational networking and compute using Terraform.

With Module 008, I am bringing both together. Instead of running workloads on a single standalone cluster, I set up a multi-cluster architecture in AWS using **Amazon EKS with Auto Mode**, **Rancher Manager**, and **AWS Lambda**.

The goal of this project is to show how to manage multiple Kubernetes clusters from a single control plane, automate cluster onboarding with a serverless function, configure Single Sign-On (SSO) with GitHub, and keep everything secure without spending money on domains or leaving resources running.

---

## Architecture

In production, it is a requirement to keep the platform management plane separate from the clusters where application workloads actually run. To follow that pattern, I built a two-cluster setup:

1. **Management Cluster (`mgmt-eks`):**
   * Provisioned with Terraform using **EKS Auto Mode**. This uses AWS-managed Karpenter behind the scenes to handle worker node scaling automatically, so I do not have to manage node groups or Auto Scaling Groups manually.
   * Runs **Rancher Manager** deployed via Helm.
   * Handles TLS using **cert-manager** with a self-signed certificate, fronted by an AWS Application Load Balancer (ALB) through the AWS Load Balancer Controller.
   * Configured with **GitHub OAuth Single Sign-On (SSO)**, mapping GitHub teams to cluster roles (Admin vs Read-Only) so access is role-based instead of using local accounts.

2. **Workload Cluster (`workload-eks`):**
   * A separate EKS Auto Mode cluster representing an application workload environment.
   * Uses IAM Roles for Service Accounts (IRSA) via OIDC so pods can talk to AWS APIs securely without hardcoded credentials.

3. **Automated Onboarding (AWS Lambda):**
   * A Python Lambda function using `boto3`.
   * When the workload cluster is ready, the Lambda calls the Rancher REST API (`POST /v3/clusters`) to get the registration token and manifest.
   * It applies the manifest to the workload cluster, bringing it into Rancher automatically without manual steps in the UI.

```text
+---------------------------------------------------------------------------------------------------+
| AWS Cloud (us-east-1)                                                                             |
|                                                                                                   |
|  +---------------------------------------------------------------------------------------------+  |
|  | Management Plane: Management VPC (172.16.0.0/16)                                            |  |
|  |                                                                                             |  |
|  |   [ Engineer / Browser ]                                                                    |  |
|  |            |                                                                                |  |
|  |            | HTTPS (Port 443) / Self-Signed TLS                                             |  |
|  |            v                                                                                |  |
|  |   +---------------------------------------------------------------------------------------+ |  |
|  |   | AWS Application Load Balancer (ALB)                                                   | |  |
|  |   +-------------------------------------------+-------------------------------------------+ |  |
|  |                                               |                                             |  |
|  |                                               v                                             |  |
|  |   +---------------------------------------------------------------------------------------+ |  |
|  |   | Management EKS Cluster (Auto Mode)                                                    | |  |
|  |   |  - AWS Load Balancer Controller (Built-in ELB Management)                             | |  |
|  |   |  - cert-manager (Internal Self-Signed Certificate Authority)                          | |  |
|  |   |  - Rancher Manager Pods (Deployed via Helm)                                           | |  |
|  |   +-------------------------------------------+-------------------------------------------+ |  |
|  +-----------------------------------------------|---------------------------------------------+  |
|                                                  |                                                |
|             +------------------------------------+------------------------------------+           |
|             |                                                                         |           |
|             | 1. REST API: POST /v3/clusters                                          |           |
|             v                                                                         |           |
|  +-----------------------------------------+                                          |           |
|  | AWS Lambda (Python / boto3)             |                                          |           |
|  |  - Generates cluster registration token |                                          |           |
|  |  - Retrieves registration manifest      |                                          |           |
|  +--------------------+--------------------+                                          |           |
|                       |                                                               |           |
|                       | 2. Apply Registration Manifest                                | 3. Telemetry
|                       v                                                               |    Tunnel
|  +---------------------------------------------------------------------------------+  |    (Outbound)
|  | Workload Plane: Workload VPC (172.17.0.0/16)                                    |  |           |
|  |                                                                                 |  |           |
|  |   +---------------------------------------------------------------------------+ |  |           |
|  |   | Workload EKS Cluster (Auto Mode)                                          | |  |           |
|  |   |  - Rancher Cattle Cluster Agent (Runs on cluster) <-----------------------+----+           |
|  |   |  - Serverless Karpenter Compute (Demand-driven EC2 Nodes)                 | |              |
|  |   |  - IAM Roles for Service Accounts (IRSA via OIDC)                         | |              |
|  |   +---------------------------------------------------------------------------+ |              |
|  +---------------------------------------------------------------------------------+              |
+---------------------------------------------------------------------------------------------------+
```

---

## Core Competencies Demonstrated

* **EKS Auto Mode:** Hands-off node management where AWS sizes and scales EC2 instances dynamically based on pod requirements, removing the need for manual node groups.
* **Centralized Cluster Governance:** Managing multiple Kubernetes clusters from one dashboard with unified visibility and access control.
* **Zero-Cost TLS:** Using `cert-manager` with an internal CA so everything runs over HTTPS (port 443) without buying an external domain.
* **Identity & Access Management:** GitHub OAuth for engineer login with team RBAC, plus IRSA so workloads use temporary STS tokens instead of static IAM keys.
* **Serverless Platform Automation:** Using a Python Lambda function to talk to Rancher's REST API and automate cluster registration.
* **Clean Lifecycle & Cost Control:** Everything is managed in Terraform so a single `terraform destroy` tears down all resources, keeping the whole lab within AWS promotional credits.

---

## Directory Structure

```text
008-eks-rancher/
├── README.md
├── modules/
│   ├── vpc/               # Reusable multi-AZ VPC module with EKS subnet tags
│   ├── eks-auto/          # Reusable EKS Auto Mode cluster module
│   ├── rancher/           # Helm releases: cert-manager, AWS Load Balancer Controller, Rancher
│   └── lambda-importer/   # Serverless Python importer function and IAM execution role
├── clusters/              # Clusters stack provisioning mgmt-eks, ALB, Rancher and workload-eks cluster
└── automation/            # Lambda deployment and test triggers
```

---

## Verification & Lifecycle Workflow

1. **Phase 1: Management Plane Provisioning:** Deploy the management VPC and `mgmt-eks` cluster, then install `cert-manager`, AWS Load Balancer Controller, and Rancher with Helm.
2. **Phase 2: Access & Identity Verification:** Access the Rancher UI over HTTPS via the ALB, configure GitHub OAuth, and verify that team permissions work as expected.
3. **Phase 3: Workload Cluster Provisioning:** Deploy the `workload-eks` cluster using EKS Auto Mode.
4. **Phase 4: Automated Onboarding:** Trigger the Lambda function to grab the registration token from Rancher's API and apply the manifest to the workload cluster. Confirm the cluster shows as `Active` in Rancher.
5. **Phase 5: Test Workload Deployment & Verification:** Deploy a lightweight Nginx application onto `workload-eks` with explicit CPU/memory requests and an Ingress resource. Verify that EKS Auto Mode dynamically spins up worker nodes and an ALB, run an HTTP 200 OK smoke test, inspect the running pods in the Rancher UI, and test self-healing by terminating an Auto Mode EC2 node to confirm automatic replacement.
6. **Phase 6: Teardown:** Run `terraform destroy` across all stacks and verify in the AWS console that all resources are deleted so no costs are left running.