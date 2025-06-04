# ConfigMap for Prometheus configuration
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

# Deployment for Prometheus
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

# Service for Prometheus
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
