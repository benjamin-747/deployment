locals {
  labels = merge({ app = var.name }, var.labels)

  # Effective requests/limits. Each override falls back to cpu/memory when empty,
  # so callers that only set cpu/memory keep requests == limits.
  requests_cpu    = var.requests_cpu != "" ? var.requests_cpu : var.cpu
  requests_memory = var.requests_memory != "" ? var.requests_memory : var.memory
  limits_cpu      = var.limits_cpu != "" ? var.limits_cpu : var.cpu
  limits_memory   = var.limits_memory != "" ? var.limits_memory : var.memory
}

resource "kubernetes_deployment_v1" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  # Controllers like k3s/Rancher inject annotations at runtime (e.g.
  # field.cattle.io/publicEndpoints). We don't manage any annotations on the
  # Deployment's top-level metadata, so ignore the whole map to avoid a
  # perpetual diff. (Ignoring a single key doesn't work when the annotations
  # map is otherwise unmanaged.) Pod template annotations use a different path
  # and are unaffected.
  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = { app = var.name }
    }

    template {
      metadata {
        labels = local.labels
      }

      spec {
        container {
          name              = "app"
          image             = var.image
          image_pull_policy = var.image_pull_policy

          port {
            container_port = var.container_port
          }

          dynamic "env" {
            for_each = var.environment
            content {
              name  = env.value.name
              value = env.value.value
            }
          }

          resources {
            # Defaults to requests == limits unless the caller sets the
            # requests_*/limits_* overrides (k3s allows overcommit).
            requests = {
              cpu    = local.requests_cpu
              memory = local.requests_memory
            }
            limits = {
              cpu    = local.limits_cpu
              memory = local.limits_memory
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    selector = { app = var.name }
    type     = var.service_type

    port {
      port        = var.container_port
      target_port = var.container_port
      protocol    = "TCP"
    }
  }
}
