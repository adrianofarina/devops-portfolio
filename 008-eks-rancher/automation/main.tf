# Automation Root Stack: Deploys the Rancher Importer Lambda

# Verify the target EKS workload cluster exists before deploying the importer
data "aws_eks_cluster" "workload" {
  name = var.workload_cluster_name
}

module "lambda_importer" {
  source = "../modules/lambda-importer"

  function_name              = "${var.environment}-rancher-cluster-importer"
  environment                = var.environment
  workload_cluster_name      = data.aws_eks_cluster.workload.name
  rancher_url_ssm_param      = "/devops-portfolio/${var.environment}/rancher/url"
  rancher_password_ssm_param = "/devops-portfolio/${var.environment}/rancher/bootstrap-password"
}
