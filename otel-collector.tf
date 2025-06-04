# Service Account for the Collector
resource "kubernetes_service_account_v1" "otel_collector" {
  metadata {
    name      = "otel-collector"
    namespace = kubernetes_namespace.network.metadata[0].name
  }
}

# ConfigMap with Collector configuration
resource "kubernetes_config_map_v1" "otel_collector_config" {
  metadata {
    name      = "otel-collector-config"
    namespace = kubernetes_namespace.network.metadata[0].name
  }
  data = {
    "config.yaml" = file("otel-collector-config.yaml")
    # "config.yaml" = yamlencode(local.otel_config)
  }
  # depends_on = [kubernetes_namespace.network]
}

# Service exposing Collector ports
resource "kubernetes_service_v1" "otel_collector" {
  metadata {
    name      = "otel-collector"
    namespace = kubernetes_namespace.network.metadata[0].name
    labels = {
      app = "otel-collector"
      # app       = "opentelemetry"
      # component = "otel-collector"
    }
  }
  spec {
    selector = {
      app = "otel-collector"
      # app       = "opentelemetry"
      # component = "otel-collector"
    }

    port {
      port        = 4317
      target_port = 4317
      protocol    = "TCP"
      name        = "otel-grpc"
    }
    port {
      port        = 4318
      target_port = 4318
      protocol    = "TCP"
      name        = "otel-http"
    }
    port {
      port        = 8889
      target_port = 8889
      protocol    = "TCP"
      name        = "metrics"
    }
    # port {
    #   port        = 55679
    #   target_port = 55679
    #   protocol    = "TCP"
    #   name        = "zpages"
    # }
    # port {
    #   port        = 54527
    #   target_port = 54527
    #   protocol    = "UDP"
    #   name        = "syslogudp"
    # }
  }
}

# Deployment OpenTelemetry Collector
resource "kubernetes_deployment_v1" "otel_collector" {
  metadata {
    name      = "otel-collector"
    namespace = kubernetes_namespace.network.metadata[0].name
    labels = {
      app = "otel-collector"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "otel-collector"
      }
    }
    min_ready_seconds         = 5
    progress_deadline_seconds = 120
    replicas                  = 1
    template {
      metadata {
        labels = {
          app = "otel-collector"
        }
      }
      spec {
        container {
          name  = "otel-collector"
          image = "otel/opentelemetry-collector-contrib:latest"
          # image = "otel/opentelemetry-collector-contrib:0.97.0"

          args = ["--config=/etc/otel/config.yaml"]
          volume_mount {
            name       = "otel-collector-config"
            mount_path = "/etc/otel"
          }
          # volume_mount {
          #   name       = "secrets"
          #   mount_path = "/etc/otelcol-contrib/secrets"
          #   read_only  = true
          # }
          resources {
            limits = {
              memory = "2Gi"
            }
            requests = {
              cpu    = "200m"
              memory = "400Mi"
            }
          }
          env {
            name = "MY_POD_IP"
            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }
          env {
            name = "KAFKA_USERNAME"
            value_from {
              secret_key_ref {
                name = "kafka-credentials"
                key  = "username"
              }
            }
          }
          env {
            name = "KAFKA_PASSWORD"
            value_from {
              secret_key_ref {
                name = "kafka-credentials"
                key  = "password"
              }
            }
          }
          env {
            name = "SNMP_AUTH_PASSWORD"
            value_from {
              secret_key_ref {
                name = "snmp-credentials"
                key  = "auth-password"
              }
            }
          }
          env {
            name = "SNMP_PRIVACY_PASSWORD"
            value_from {
              secret_key_ref {
                name = "snmp-credentials"
                key  = "privacy-password"
              }
            }
          }
          env {
            name = "K8S_NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          #           port {
          #   container_port = 54526
          #   name           = "syslogtcp"
          # }
          # port {
          #   container_port = 54527
          #   name           = "syslogudp"
          #   protocol       = "UDP"
          # }
          # port {
          #   container_port = 54528
          #   name           = "syslogtcptls"
          # }
          # # Default endpoint for ZPages.
          # port {
          #   container_port = 55679
          #   name           = "zpages"
          # }
          # # Default endpoint for OpenTelemetry receiver.
          # port {
          #   container_port = 4317
          #   name           = "otel-grpc"
          # }
          # # Default endpoint for Jaeger gRPC receiver.
          # port {
          #   container_port = 14250
          #   name           = "jaeger-grpc"
          # }
          # # Default endpoint for Jaeger HTTP receiver.
          # port {
          #   container_port = 14268
          #   name           = "jaeger-http"
          # }
          # # Default endpoint for Zipkin receiver.
          # port {
          #   container_port = 9411
          #   name           = "zipkin"
          # }
          # # Default endpoint for querying metrics.
          # port {
          #   container_port = 8888
          #   name           = "metrics"
          # }
          port {
            container_port = 4317
            name           = "grpc"
          }
          port {
            container_port = 4318
            name           = "http"
          }
          port {
            container_port = 8889
            name           = "metrics"
          }
        }
        volume {
          name = "otel-collector-config"
          config_map {
            name = kubernetes_config_map_v1.otel_collector_config.metadata[0].name
          }
        }

        # volume {
        #   name = "secrets"
        #   projected {
        #     sources {
        #       dynamic "secret" {
        #         for_each = local.certs
        #         content {
        #           name = replace(secret.value, ".", "-")
        #           items {
        #             key  = "tls.crt"
        #             path = "${replace(secret.value, ".", "-")}.crt"
        #           }
        #           items {
        #             key  = "tls.key"
        #             path = "${replace(secret.value, ".", "-")}.key"
        #           }
        #         }
        #       }
        #     }
        #   }
        # }
      }
    }
  }
  # depends_on = [kubernetes_manifest.certs]
}