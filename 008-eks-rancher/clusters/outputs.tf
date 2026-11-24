output "mgmt_cluster_name" {
  description = "Management EKS cluster name"
  value       = module.mgmt_eks.cluster_name
}

output "workload_cluster_name" {
  description = "Target workload EKS cluster name"
  value       = module.workload_eks.cluster_name
}

output "rancher_url" {
  description = "HTTPS URL for the Rancher UI and API"
  value       = module.rancher.rancher_url
}

output "nginx_test_url" {
  description = "HTTP URL for the Nginx test workload ALB on workload-eks"
  value       = var.deploy_test_workload ? "http://${kubernetes_ingress_v1.nginx[0].status[0].load_balancer[0].ingress[0].hostname}" : null
}

output "workload_irsa_demo_role_arn" {
  description = "Demo IRSA IAM role ARN on the workload cluster"
  value       = module.workload_eks.irsa_demo_role_arn
}

output "rancher_url_ssm_param" {
  description = "SSM Parameter storing the Rancher URL"
  value       = aws_ssm_parameter.rancher_url.name
}

output "rancher_password_ssm_param" {
  description = "SSM Parameter storing the Rancher bootstrap password"
  value       = aws_ssm_parameter.rancher_password.name
}

output "kubeconfig_commands" {
  description = "Commands to update local kubeconfig for both clusters"
  value = {
    management = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.mgmt_eks.cluster_name} --alias ${module.mgmt_eks.cluster_name}"
    workload   = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.workload_eks.cluster_name} --alias ${module.workload_eks.cluster_name}"
  }
}
