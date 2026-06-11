resource "kubernetes_namespace_v1" "demo" {
  metadata {
    name   = var.namespace
    labels = { managed-by = "terraform" }
  }

  # k3s/Rancher injects several annotations on namespaces at runtime. We don't
  # manage any namespace annotations ourselves, so ignore the whole map to avoid
  # a perpetual diff on every plan.
  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}
