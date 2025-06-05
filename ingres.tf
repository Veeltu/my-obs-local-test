resource "kubernetes_ingress_v1" "prometheus_ui" {
  metadata {
    name      = "prometheus-ui"
    namespace = kubernetes_namespace.my-network.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "public" # MikroK8s using "public", not "nginx"!
      # "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      # "cert-manager.io/cluster-issuer" = "letsencrypt-prod" # if using cert-managera
    }
  }

  spec {
    rule {
      host = "prometheus.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.prometheus.metadata[0].name
              port {
                number = 9090
              }
            }
          }
        }
      }
    }

    # tls {
    #   hosts       = ["prometheus.local"]
    #   secret_name = "prometheus-tls-secret"
    # }
  }
}


resource "kubernetes_ingress_v1" "otel_ui" {
  metadata {
    name      = "otel-ui"
    namespace = kubernetes_namespace.my-network.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "public"
      # "nginx.ingress.kubernetes.io/rewrite-target" = "/" # if you need rewrite path
    }
  }

  spec {
    rule {
      host = "otel.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.otel_collector.metadata[0].name
              port {
                number = 8889 # Port HTTP serwis
              }
            }
          }
        }
      }
    }

    # tls {
    #   hosts       = ["otel.local"]
    #   secret_name = "otel-tls-secret"
    # }
  }
}
