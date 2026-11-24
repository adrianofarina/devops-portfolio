# Rancher Platform Deployment (EKS Auto Mode IngressClass, cert-manager, Rancher)

# Native EKS Auto Mode ALB IngressClass (deployed via local chart to avoid plan-time CRD checks)
resource "helm_release" "alb_ingress_class" {
  name      = "alb-ingress-class"
  chart     = "${path.module}/charts/alb-ingress-class"
  namespace = "kube-system"
  wait      = true
}

# cert-manager (Internal TLS signing inside the cluster)
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  chart            = "oci://quay.io/jetstack/charts/cert-manager"
  version          = var.cert_manager_version
  namespace        = "cert-manager"
  create_namespace = true
  wait             = true
  timeout          = 600

  set = [
    {
      name  = "crds.enabled"
      value = "true"
    },
    {
      name  = "resources.requests.cpu"
      value = "100m"
    },
    {
      name  = "resources.requests.memory"
      value = "256Mi"
    }
  ]
}

# Rancher Manager
resource "helm_release" "rancher" {
  name             = "rancher"
  repository       = "https://releases.rancher.com/server-charts/latest"
  chart            = "rancher"
  namespace        = "cattle-system"
  create_namespace = true
  wait             = true
  timeout          = 600

  set = [
    {
      name  = "hostname"
      value = var.rancher_hostname
    },
    {
      name  = "replicas"
      value = tostring(var.rancher_replicas)
    },
    # Use cert-manager to generate internal Rancher self-signed TLS
    {
      name  = "tls"
      value = "rancher"
    },
    # Disable chart default ingress so we control the AWS ALB Ingress directly
    {
      name  = "ingress.enabled"
      value = "false"
    },
    # Sizing requests so EKS Auto Mode picks the right EC2 compute automatically
    {
      name  = "resources.requests.cpu"
      value = "500m"
    },
    {
      name  = "resources.requests.memory"
      value = "2Gi"
    },
    {
      name  = "resources.limits.memory"
      value = "4Gi"
    }
  ]

  set_sensitive = [
    {
      name  = "bootstrapPassword"
      value = var.rancher_bootstrap_password
    }
  ]

  depends_on = [
    helm_release.cert_manager,
    helm_release.alb_ingress_class,
  ]
}

# AWS Application Load Balancer Ingress for Rancher (HTTPS :443)
resource "kubernetes_ingress_v1" "rancher" {
  wait_for_load_balancer = true

  metadata {
    name      = "rancher-alb-ingress"
    namespace = "cattle-system"

    annotations = {
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/listen-ports"     = jsonencode([{ HTTPS = 443 }])
      "alb.ingress.kubernetes.io/certificate-arn"  = aws_acm_certificate.this.arn
      "alb.ingress.kubernetes.io/backend-protocol" = "HTTPS"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/healthz"
      "alb.ingress.kubernetes.io/success-codes"    = "200,302"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      # Omitting host lets traffic hit the AWS-generated ALB DNS directly without a custom domain
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "rancher"
              port {
                number = 443
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.rancher]
}
