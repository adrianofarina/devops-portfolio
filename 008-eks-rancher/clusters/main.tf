# Clusters Root Stack: Management Plane (EKS Auto Mode + Rancher) & Target Workload Cluster

data "aws_availability_zones" "available" {
  state = "available"
}

# Management Plane VPC & EKS Auto Mode Cluster
module "mgmt_vpc" {
  source = "../modules/vpc"

  vpc_cidr              = "172.16.0.0/16"
  public_subnet_1_cidr  = "172.16.1.0/24"
  public_subnet_2_cidr  = "172.16.2.0/24"
  private_subnet_1_cidr = "172.16.10.0/24"
  private_subnet_2_cidr = "172.16.20.0/24"
  az1                   = data.aws_availability_zones.available.names[0]
  az2                   = data.aws_availability_zones.available.names[1]
  cluster_name          = var.mgmt_cluster_name
  environment           = var.environment
}

module "mgmt_eks" {
  source = "../modules/eks-auto"

  cluster_name           = var.mgmt_cluster_name
  kubernetes_version     = "1.36"
  subnet_ids             = module.mgmt_vpc.private_subnet_ids
  endpoint_public_access = true
  admin_principal_arns   = []
  environment            = var.environment
}

# Rancher Manager Platform (deployed onto Management EKS)
module "rancher" {
  source = "../modules/rancher"

  aws_region                 = var.aws_region
  environment                = var.environment
  rancher_hostname           = "rancher.internal"
  rancher_bootstrap_password = var.rancher_bootstrap_password
  rancher_replicas           = 1
  cert_manager_version       = "v1.21.3"

  depends_on = [module.mgmt_eks]
}

# Target Workload VPC & EKS Auto Mode Cluster
module "workload_vpc" {
  source = "../modules/vpc"

  vpc_cidr              = "172.17.0.0/16"
  public_subnet_1_cidr  = "172.17.1.0/24"
  public_subnet_2_cidr  = "172.17.2.0/24"
  private_subnet_1_cidr = "172.17.10.0/24"
  private_subnet_2_cidr = "172.17.20.0/24"
  az1                   = data.aws_availability_zones.available.names[0]
  az2                   = data.aws_availability_zones.available.names[1]
  cluster_name          = var.workload_cluster_name
  environment           = var.environment
}

module "workload_eks" {
  source = "../modules/eks-auto"

  cluster_name           = var.workload_cluster_name
  kubernetes_version     = "1.36"
  subnet_ids             = module.workload_vpc.private_subnet_ids
  endpoint_public_access = true
  admin_principal_arns   = []
  environment            = var.environment
}

# Store Rancher connection details in SSM Parameter Store for the decoupled automation stack
resource "aws_ssm_parameter" "rancher_url" {
  name        = "/devops-portfolio/${var.environment}/rancher/url"
  description = "Rancher ALB HTTPS URL"
  type        = "String"
  value       = module.rancher.rancher_url
}

resource "aws_ssm_parameter" "rancher_password" {
  name        = "/devops-portfolio/${var.environment}/rancher/bootstrap-password"
  description = "Rancher bootstrap admin password"
  type        = "SecureString"
  value       = var.rancher_bootstrap_password
}
