# Ingress dla Prometheusa
resource "kubernetes_ingress_v1" "prometheus_ui" {
  metadata {
    name      = "prometheus-ui"
    namespace = kubernetes_namespace.network.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      # Opcjonalne adnotacje:
      # "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      # "cert-manager.io/cluster-issuer" = "letsencrypt-prod" # Jeśli używasz cert-managera
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

    # Sekcja TLS (opcjonalnie)
    # tls {
    #   hosts       = ["prometheus.local"]
    #   secret_name = "prometheus-tls-secret"
    # }
  }
}
