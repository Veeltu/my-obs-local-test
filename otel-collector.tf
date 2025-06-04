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
  depends_on = [kubernetes_namespace.network]
}

# Service exposing Collector ports
resource "kubernetes_service_v1" "otel_collector" {
  metadata {
    name      = "otel-collector"
    namespace = kubernetes_namespace.network.metadata[0].name
    labels = {
      app       = "opentelemetry"
      component = "otel-collector"
    }
  }
  spec {
    selector = {
      app       = "opentelemetry"
      component = "otel-collector"
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