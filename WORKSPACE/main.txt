# Namespace dla sieci i OpenTelemetry Collector
resource "kubernetes_namespace" "network" {
  metadata {
    name = "network"
  }
}

# ConfigMap z konfiguracją OpenTelemetry Collector
resource "kubernetes_config_map_v1" "otel_collector_config" {
  metadata {
    name      = "otel-collector-config"
    namespace = kubernetes_namespace.network.metadata[0].name
  }
  data = {
    "config.yaml" = file("otel-collector-config.yaml")
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
    replicas = 1
    selector {
      match_labels = {
        app = "otel-collector"
      }
    }
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
          args  = ["--config=/etc/otel/config.yaml"]
          volume_mount {
            name       = "otel-collector-config"
            mount_path = "/etc/otel"
          }
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
            name           = "prom-metrics"
          }
        }
        volume {
          name = "otel-collector-config"
          config_map {
            name = kubernetes_config_map_v1.otel_collector_config.metadata[0].name
          }
        }
      }
    }
  }
}

# Service OpenTelemetry Collector
resource "kubernetes_service_v1" "otel_collector" {
  metadata {
    name      = "otel-collector"
    namespace = kubernetes_namespace.network.metadata[0].name
  }
  spec {
    selector = {
      app = "otel-collector"
    }
    port {
      name        = "grpc"
      port        = 4317
      target_port = 4317
    }
    port {
      name        = "http"
      port        = 4318
      target_port = 4318
    }
    port {
      name        = "prom-metrics"
      port        = 8889
      target_port = 8889
    }
  }
}

# Ingress dla OpenTelemetry Collector metrics
# resource "kubernetes_ingress_v1" "otel_collector_metrics" {
#   metadata {
#     name      = "otel-collector-metrics"
#     namespace = kubernetes_namespace.network.metadata[0].name
#   }
#   spec {
#     rule {
#       host = "otel-metrics.local"
#       http {
#         path {
#           path      = "/metrics"
#           path_type = "Prefix"
#           backend {
#             service {
#               name = kubernetes_service_v1.otel_collector.metadata[0].name
#               port {
#                 number = 8889
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }

# Namespace dla Prometheusa
# resource "kubernetes_namespace" "monitoring" {
#   metadata {
#     name = "monitoring"
#   }
# }

# ConfigMap Prometheusa z konfiguracją scrape
resource "kubernetes_config_map_v1" "prometheus_config" {
  metadata {
    name      = "prometheus-config"
    namespace = kubernetes_namespace.network.metadata[0].name
  }
  data = {
    "prometheus.yml" = yamlencode({
      global = {
        scrape_interval = "15s"
      }
      scrape_configs = [
        {
          job_name     = "otel-collector"
          metrics_path = "/metrics"
          static_configs = [
            {
              targets = ["otel-collector.network.svc.cluster.local:8889"]
            }
          ]
        }
      ]
    })
  }
}

# Deployment Prometheusa
resource "kubernetes_deployment_v1" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.network.metadata[0].name
    labels = {
      app = "prometheus"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "prometheus"
      }
    }
    template {
      metadata {
        labels = {
          app = "prometheus"
        }
      }
      spec {
        container {
          name  = "prometheus"
          image = "prom/prometheus:v2.46.0"
          args = [
            "--config.file=/etc/prometheus/prometheus.yml",
            "--storage.tsdb.path=/prometheus",
            "--web.console.libraries=/usr/share/prometheus/console_libraries",
            "--web.console.templates=/usr/share/prometheus/consoles"
          ]
          port {
            container_port = 9090
            name           = "web"
          }
          volume_mount {
            name       = "config-volume"
            mount_path = "/etc/prometheus"
          }
          volume_mount {
            name       = "data"
            mount_path = "/prometheus"
          }
        }
        volume {
          name = "config-volume"
          config_map {
            name = kubernetes_config_map_v1.prometheus_config.metadata[0].name
          }
        }
        volume {
          name = "data"
          empty_dir {}
        }
      }
    }
  }
}

# Service Prometheusa
resource "kubernetes_service_v1" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.network.metadata[0].name
  }
  spec {
    selector = {
      app = "prometheus"
    }
    port {
      name        = "web"
      port        = 9090
      target_port = 9090
    }
    type = "ClusterIP"
  }
}
