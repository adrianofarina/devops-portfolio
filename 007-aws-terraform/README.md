# 007 - AWS Cloud Infrastructure as Code with Terraform

In previous modules, I engineered container workloads, Helm packaging, GitOps continuous delivery with ArgoCD, and distributed CI automation with Jenkins. In this module, I step into foundational cloud engineering by provisioning a multi-tier, production-ready cloud architecture on **Amazon Web Services (AWS)** using **Terraform**, the industry-standard Infrastructure as Code (IaC) tool by HashiCorp.

To reflect modern cloud-native standards, this project emphasizes:
- Modular, DRY (Don't Repeat Yourself) Terraform architecture with decoupled network and compute modules.
- Strict network segmentation across three distinct functional tiers (Public, Private App, Secure Database).
- Least-privilege ingress and egress security filtering.
- Automated lifecycle management with deterministic zero-cost teardown via `terraform destroy`.

---

## 1. Cloud Architecture & Design Strategy

The infrastructure implements a classic enterprise 3-tier network topology inside a dedicated Virtual Private Cloud (VPC):

```text
+-----------------------------------------------------------------------------------------+
|                                    AWS Cloud (Region: us-east-1)                        |
|  VPC: 172.16.0.0/16                                                                     |
|                                                                                         |
|  +-----------------------------------------------------------------------------------+  |
|  | Public Subnet (172.16.1.0/24)                                                     |  |
|  |  - Internet Gateway (IGW)                                                         |  |
|  |  - NAT Gateway (Elastic IP)                                                       |  |
|  |  - Application Load Balancer (ALB / HTTP 80 & HTTPS 443)                          |  |
|  +-----------------------------------------+-----------------------------------------+  |
|                                            | Forward Ingress / NAT Egress               |
|                                            v                                            |
|  +-----------------------------------------------------------------------------------+  |
|  | Private Subnet (172.16.2.0/24)                                                    |  |
|  |  - Backend Application Workloads (Private IP only)                                |  |
|  |  - Ingress: HTTP/8080 allowed strictly from ALB Security Group                    |  |
|  |  - Zero-Port Administration: Managed via AWS Systems Manager (SSM) Session Manager|  |
|  |  - Egress: Outbound traffic routed through NAT Gateway in Public Subnet           |  |
|  +-----------------------------------------------------------------------------------+  |
|                                                                                         |
|  +-----------------------------------------------------------------------------------+  |
|  | Secure Subnet (172.16.3.0/24)                                                     |  |
|  |  - Isolated data tier (No direct route to Internet Gateway or NAT Gateway)        |  |
|  |  - Ingress: Database ports allowed strictly from Security subnet.                 |  |
|  +-----------------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------------------+
```

### Architectural Highlights
- **VPC & 3-Tier Subnets**: High isolation boundary preventing public internet access to application runtimes and databases.
- **NAT Gateway Egress**: Backend workloads in the private subnet can securely initiate outbound requests (e.g., pulling OS updates or container images) without exposing incoming open ports to the internet.
- **Zero-Port Administration (AWS SSM)**: Eliminates jump hosts and open SSH ports entirely. Administrative access is performed securely via AWS Systems Manager (SSM) Session Manager authenticated through IAM roles.
- **Ingress Gateway (HTTP Port 80 vs. Enterprise HTTPS Port 443 with TLS & ACM)**:
  - **Lab & Portfolio Context (Port 80)**: The Application Load Balancer (`ext_gateway`) is intentionally configured to listen on HTTP port 80 using the AWS-assigned public DNS hostname (`*.elb.amazonaws.com`). This deliberate architectural choice allows seamless, zero-cost browser verification while completely avoiding recurring expenses associated with purchasing a custom registered domain and paying monthly AWS Route 53 hosted zone fees ($0.50/month).
  - **Enterprise Production Reality (Port 443 with TLS & ACM)**: In a live production deployment, the load balancer would strictly terminate encrypted HTTPS traffic on port 443 using modern TLS 1.3 protocol policies (`ELBSecurityPolicy-TLS13-1-2-2021-06`). An SSL/TLS certificate would be provisioned and automatically managed through **AWS Certificate Manager (ACM)**, validated via DNS ownership records for a corporate custom domain (e.g., `app.company.com`). The HTTP port 80 listener would be configured with an automated HTTP 301 permanent redirect to port 443, ensuring that all data in transit across the public internet is encrypted before forwarding to backend private instances.

---

## 2. Prerequisites & AWS Authentication

### Tooling Requirements
- **Terraform CLI**: `>= 1.5.0`
- **AWS CLI**: For credential management and API verification.

### Configuring AWS Credentials
Terraform interacts with AWS APIs through standard AWS credential providers. Before executing Terraform commands, I authenticate using one of the following methods:

**Method 1: Environment Variables (Preferred for Ephemeral Sessions)**
```bash
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_DEFAULT_REGION="eu-central-1"
```

**Method 2: AWS CLI Profile**
```bash
aws configure
# Enter AWS Access Key ID, Secret Access Key, and default region
```

---

## 3. Terraform State Management: Enterprise Standards vs. Portfolio Context

Understanding Terraform state (`terraform.tfstate`) is critical to enterprise DevOps operations:

### Enterprise Reality: Remote State with Distributed Locking
In a production team environment, storing state files on a local developer machine is strictly prohibited because:
1. **State Locking**: Without locking, two concurrent `terraform apply` operations can overwrite state and corrupt live infrastructure.
2. **Secret Exposure**: Resource attributes stored in state files (passwords, private keys, connection strings) are unencrypted in plaintext on disk.
3. **Collaboration Drift**: Team members cannot easily synchronize state across distributed workstations.

#### Modern Enterprise Standard (Terraform 1.10+): S3-Native State Locking
Following AWS's introduction of native conditional writes to Amazon S3, **Terraform 1.10+ officially supports native S3 state locking**. DynamoDB is no longer required:

```hcl
terraform {
  backend "s3" {
    bucket       = "company-tfstate-prod"
    key          = "007-aws-terraform/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # S3-native state locking (DynamoDB no longer required)
  }
}
```

- **How It Works**: When a write operation begins (`terraform apply`), Terraform creates a temporary `<state-key>.tflock` file directly in the S3 bucket using native conditional writes (`PutObject` with conditional checks). Once the operation finishes, Terraform deletes the lock file.
- **Architectural Advantages**:
  - **Zero DynamoDB Dependency**: Eliminates the overhead of provisioning, maintaining, and paying for separate DynamoDB tables (`dynamodb_table = "terraform-state-lock"`).
  - **Simplified IAM Security**: Deployment IAM roles only need S3 bucket permissions (`s3:GetObject`, `s3:PutObject`, `s3:DeleteObject`), removing all `dynamodb:*` access requirements.
  - **Single Service Footprint**: Remote state is encapsulated entirely within a single S3 bucket.

#### Historical Context (Pre-Terraform 1.10): S3 + DynamoDB Locking
Before Terraform 1.10 and S3 conditional writes, S3 lacked atomic write-locking capabilities. Teams had to provision a dedicated DynamoDB table with a primary key named `LockID` (String):

```hcl
# Legacy Pre-1.10 Configuration:
terraform {
  backend "s3" {
    bucket         = "company-tfstate-prod"
    key            = "007-aws-terraform/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### Portfolio Context: Local State with Strict `.gitignore` Protection
For this portfolio project, I intentionally maintain the state locally:
- Eliminates the requirement to pre-provision an external S3 bucket before running the lab.
- Prevents recurring cloud storage and transaction charges when testing and tearing down environments.
- Local state files (`*.tfstate`, `*.tfstate.backup`, `.terraform/`) are strictly excluded from version control via the root `.gitignore`.
- When ready, the configuration can be migrated to the modern S3 backend (`use_lockfile = true`) with a single `terraform init -migrate-state` execution.

---

## 4. Directory Layout

```text
007-aws-terraform/
├── README.md               # Architecture documentation and lab walkthrough
├── network/                # Root 1: Network Foundation Layer
│   ├── providers.tf        # AWS provider configuration for network
│   ├── variables.tf        # Network-specific input variables
│   ├── main.tf             # Calls module "vpc" (../modules/vpc)
│   └── outputs.tf          # Exports VPC, subnet IDs, and NAT gateway IP
├── servers/                # Root 2: Compute & Workload Layer
│   ├── providers.tf        # AWS provider configuration for compute
│   ├── variables.tf        # Compute-specific input variables
│   ├── main.tf             # Reads network state, calls ext_gateway & ec2_instance
│   └── outputs.tf          # Exports compute endpoints (ALB DNS, ASG name, SG IDs)
└── modules/
    ├── vpc/                # Reusable VPC module (Multi-AZ subnets, IGW, NAT, NACLs)
    ├── ec2-instance/       # Reusable compute module (Dynamic AMI, ASG, Launch Template, user data)
    └── gateway/            # Reusable ingress module (ALB, Security Group, Target Group, HTTP listener)
```

---

## 5. Implementation Roadmap

1. **Root Configuration**: Configure the `hashicorp/aws` provider, default resource tags, and region placeholders.
2. **Network Layer (`network/`)**: Provision the VPC (`172.16.0.0/16`), 3-tier subnets (public, private app, secure database), Internet Gateway, NAT Gateway, and stateless NACLs via `modules/vpc`.
3. **Compute Layer (`servers/`)**: Provision Security Groups, Application Load Balancer (ALB), and Auto Scaling Group (ASG) / compute workloads in the private subnet.
4. **Validation & Deployment**: Execute `terraform init`, `terraform plan`, and `terraform apply`.
   - `terraform init`: Standard initialization (downloads providers, indexes modules, and configures backend).
   - `terraform init -backend=false`: Initializes plugins and modules for validation (`terraform validate`) without connecting to state storage.
   - `terraform init -upgrade`: Upgrades provider plugins to the latest release allowed by the version constraints.
   - `terraform init -migrate-state`: Reconfigures and migrates state between backends (e.g., local state to remote S3).
5. **Session Manager Administration**: Configure AWS Systems Manager (SSM) for zero-port, credential-less administrative access to private instances.
6. **Zero-Cost Teardown**: Execute `terraform destroy` across both layers to cleanly terminate all AWS resources and avoid cloud billing.
