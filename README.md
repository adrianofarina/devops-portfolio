# Cloud-Native and DevOps Engineering Lab
**By Adriano Farina**

Welcome to my personal DevOps and Cloud-Native engineering repository. This project serves as a hands-on, practical showcase of real-world infrastructure, deployment workflows, and modern operational tooling.

Rather than relying purely on theoretical concepts, this repository documents practical execution—building, testing, troubleshooting, and evolving containerized architectures from foundational primitives up to production-grade GitOps delivery.

---

## Roadmap and Exercise Index

1. **[001 - Kubectl First Steps](./001-kubectl-first-steps/)**  
   Foundational Kubernetes lifecycle management: Provisioning custom namespaces, deploying containerized applications, dynamic scaling, port-forwarding, live in-line editing, and incident root-cause triage (ImagePullBackOff, describe, logs).

2. **[002 - Helming](./002-helming/)**  
   Transitioning to enterprise packaging: Replacing brittle static manifests with reusable Helm charts, establishing SemVer release management, understanding template rendering, and enforcing multi-environment namespace portability.

3. **[003 - GitHub Actions](./003-github-actions/)**  
   Automated Continuous Integration (CI): Creating cloud workflows to automatically lint manifests, validate Helm charts, compile templates, and protect the main branch with automated test gates.

4. **[004 - ArgoCD](./004-argocd/)**  
   Declarative GitOps Continuous Delivery (CD): Zero-downtime adoption of an existing Helm workload, manual drift detection, immutable Git tag releases and UI rollbacks, and GitHub OAuth SSO via Dex with RBAC.

5. **[005 - Prometheus & Grafana](./005-prometheus-grafana/)**  
   Cloud-native observability stack (`kube-prometheus-stack`): Operator-driven Prometheus metrics scraping, PromQL queries, pre-built Grafana Kubernetes dashboards, `kube-state-metrics`, and Alertmanager alert threshold testing.

6. **[006 - Jenkins CI: Enterprise Pipeline Engineering](./006-jenkins-ci/)**  
   Self-hosted automation server and distributed CI architecture: Deploying a lightweight Jenkins Controller and containerized Agent, authoring production-grade Declarative Jenkinsfiles (Groovy syntax), stage view visualization, post-actions, and Jenkins-to-GitHub Actions translation.

7. **[007 - AWS Cloud Infrastructure as Code with Terraform](./007-aws-terraform/)**  
   Production-grade Infrastructure as Code (IaC) featuring reusable Terraform modules: Provisioning an AWS VPC (10.0.0.0/16), 3-tier subnets (Public, Private App, Secure Database), NAT Gateway, Security Groups, Bastion and private EC2 instances, state inspection, and zero-cost automated lifecycle management via 'terraform destroy'.
