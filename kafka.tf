# Namespace (jeśli chcesz mieć Kafka w tym samym co reszta, pomiń ten blok)
# resource "kubernetes_namespace" "network" {
#   metadata {
#     name = "network"
#   }
# }

# Zookeeper Deployment (wymagany przez Kafkę)
resource "kubernetes_deployment_v1" "zookeeper" {
  metadata {
    name      = "zookeeper"
    namespace = kubernetes_namespace.network.metadata[0].name
    labels = {
      app = "zookeeper"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "zookeeper"
      }
    }
    template {
      metadata {
        labels = {
          app = "zookeeper"
        }
      }
      spec {
        container {
          name  = "zookeeper"
          image = "bitnami/zookeeper:3.8"
          env {
            name  = "ALLOW_ANONYMOUS_LOGIN"
            value = "yes"
          }
          port {
            container_port = 2181
            name           = "client"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "zookeeper" {
  metadata {
    name      = "zookeeper"
    namespace = kubernetes_namespace.network.metadata[0].name
  }
  spec {
    selector = {
      app = "zookeeper"
    }
    port {
      port        = 2181
      target_port = 2181
      name        = "client"
    }
    type = "ClusterIP"
  }
}

# Kafka Deployment
resource "kubernetes_deployment_v1" "kafka" {
  metadata {
    name      = "kafka"
    namespace = kubernetes_namespace.network.metadata[0].name
    labels = {
      app = "kafka"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "kafka"
      }
    }
    template {
      metadata {
        labels = {
          app = "kafka"
        }
      }
      spec {
        container {
          name  = "kafka"
          image = "bitnami/kafka:3.7"
          env {
            name  = "KAFKA_BROKER_ID"
            value = "1"
          }
          env {
            name  = "KAFKA_ZOOKEEPER_CONNECT"
            value = "${kubernetes_service_v1.zookeeper.metadata[0].name}:2181"
          }
          env {
            name  = "ALLOW_PLAINTEXT_LISTENER"
            value = "yes"
          }
          env {
            name  = "KAFKA_LISTENERS"
            value = "PLAINTEXT://:9092"
          }
          env {
            name  = "KAFKA_ADVERTISED_LISTENERS"
            value = "PLAINTEXT://kafka.${kubernetes_namespace.network.metadata[0].name}.svc.cluster.local:9092"
          }
          port {
            container_port = 9092
            name           = "kafka"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "kafka" {
  metadata {
    name      = "kafka"
    namespace = kubernetes_namespace.network.metadata[0].name
  }
  spec {
    selector = {
      app = "kafka"
    }
    port {
      port        = 9092
      target_port = 9092
      name        = "kafka"
    }
    type = "ClusterIP"
  }
}
