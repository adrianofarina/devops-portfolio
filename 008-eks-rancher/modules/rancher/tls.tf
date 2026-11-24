# Zero-Cost Self-Signed TLS Certificate for AWS ALB (Imported into ACM)

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "this" {
  private_key_pem = tls_private_key.this.private_key_pem

  subject {
    common_name  = "*.${var.aws_region}.elb.amazonaws.com"
    organization = "DevOps Portfolio Lab"
  }

  dns_names = [
    "*.${var.aws_region}.elb.amazonaws.com",
    "*.elb.amazonaws.com",
    var.rancher_hostname,
  ]

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "this" {
  private_key      = tls_private_key.this.private_key_pem
  certificate_body = tls_self_signed_cert.this.cert_pem

  tags = {
    Name        = "${var.environment}-rancher-self-signed"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}
