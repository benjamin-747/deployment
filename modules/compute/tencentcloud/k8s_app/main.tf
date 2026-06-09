locals {
  labels = merge({ app = var.name }, var.labels)

  # On TKE super (serverless) nodes, this annotation makes the eklet attach a
  # public EIP to the pod so it can reach the internet (egress).
  pod_annotations = var.enable_eip ? {
    "eks.tke.cloud.tencent.com/eip-attributes" = jsonencode({
      InternetChargeType      = var.eip_charge_type
      InternetMaxBandwidthOut = var.eip_bandwidth
    })
  } : {}
}

resource "kubernetes_deployment_v1" "this" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = { app = var.name }
    }

    template {
      metadata {
        labels      = local.labels
        annotations = local.pod_annotations
      }

      spec {
        container {
          name  = "app"
          image = var.image

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
            # On TKE super (serverless) nodes requests must equal limits.
            requests = {
              cpu    = var.cpu
              memory = var.memory
            }
            limits = {
              cpu    = var.cpu
              memory = var.memory
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
