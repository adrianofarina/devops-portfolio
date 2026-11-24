output "rancher_alb_hostname" {
  description = "Public DNS hostname of the AWS Application Load Balancer for Rancher"
  value       = kubernetes_ingress_v1.rancher.status[0].load_balancer[0].ingress[0].hostname
}

output "rancher_url" {
  description = "HTTPS URL to access Rancher Manager UI and REST API"
  value       = "https://${kubernetes_ingress_v1.rancher.status[0].load_balancer[0].ingress[0].hostname}"
}

output "acm_certificate_arn" {
  description = "ARN of the self-signed certificate imported into AWS ACM"
  value       = aws_acm_certificate.this.arn
}
