# Namespace for all monitoring resources
resource "kubernetes_namespace" "my-network3" {
  metadata {
    name = "my-network3"
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
