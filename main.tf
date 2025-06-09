# Namespace for all monitoring resources
resource "kubernetes_namespace" "my_network" {
  metadata {
    name = "my-network"
    annotations = {
      "sidecar.opentelemetry.io/inject" = "true"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["cattle.io/status"],
      metadata[0].annotations["lifecycle.cattle.io/create.namespace-auth"],
    ]
  }
}
