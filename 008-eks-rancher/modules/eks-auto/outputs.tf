output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Endpoint URL for the Kubernetes API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded certificate authority data for the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider for IRSA"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "Issuer URL for the cluster OIDC provider"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "irsa_demo_role_arn" {
  description = "ARN of the demo IRSA IAM role"
  value       = aws_iam_role.irsa_demo.arn
}

output "node_role_arn" {
  description = "ARN of the Auto Mode worker node IAM role"
  value       = aws_iam_role.node.arn
}
