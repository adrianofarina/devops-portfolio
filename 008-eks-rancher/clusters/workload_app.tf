# Phase 5 Test Workload: Nginx Server + ALB Ingress on Workload EKS Cluster
# Deploying this triggers EKS Auto Mode to spin up EC2 worker nodes automatically.

resource "helm_release" "workload_alb_ingress_class" {
  count    = var.deploy_test_workload ? 1 : 0
  provider = helm.workload

  name      = "alb-ingress-class"
  chart     = "${path.module}/../modules/rancher/charts/alb-ingress-class"
  namespace = "kube-system"
  wait      = true

  depends_on = [module.workload_eks]
}

resource "kubernetes_namespace_v1" "demo_nginx" {
  count    = var.deploy_test_workload ? 1 : 0
  provider = kubernetes.workload

  metadata {
    name = "demo-nginx"
  }

  depends_on = [module.workload_eks]
}

resource "kubernetes_deployment_v1" "nginx" {
  count    = var.deploy_test_workload ? 1 : 0
  provider = kubernetes.workload

  metadata {
    name      = "nginx-test"
    namespace = kubernetes_namespace_v1.demo_nginx[0].metadata[0].name
    labels = {
      app = "nginx-test"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "nginx-test"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx-test"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:alpine"

          port {
            container_port = 80
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              memory = "256Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "nginx" {
  count    = var.deploy_test_workload ? 1 : 0
  provider = kubernetes.workload

  metadata {
    name      = "nginx-test-svc"
    namespace = kubernetes_namespace_v1.demo_nginx[0].metadata[0].name
  }

  spec {
    selector = {
      app = "nginx-test"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "nginx" {
  count                  = var.deploy_test_workload ? 1 : 0
  provider               = kubernetes.workload
  wait_for_load_balancer = true

  metadata {
    name      = "nginx-test-alb"
    namespace = kubernetes_namespace_v1.demo_nginx[0].metadata[0].name

    annotations = {
      "alb.ingress.kubernetes.io/scheme"       = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"  = "ip"
      "alb.ingress.kubernetes.io/listen-ports" = jsonencode([{ HTTP = 80 }])
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.nginx[0].metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.workload_alb_ingress_class]
}
