# RustFS — high-performance, S3-compatible object storage (MinIO alternative,
# Apache-2.0, written in Rust). Replaces the Tencent Cloud COS / external S3 the
# cloud stack used. Single-node single-disk mode; data on a longhorn PVC.
#   S3 API   : :9000  (consumed by mono-engine / orion-server)
#   Console  : :9001  (web UI)

resource "kubernetes_secret_v1" "rustfs" {
  count = var.enable_rustfs ? 1 : 0

  metadata {
    name      = "rustfs-auth"
    namespace = local.ds_ns
  }

  data = {
    access-key = var.rustfs_access_key
    secret-key = var.rustfs_secret_key
  }
}

resource "kubernetes_stateful_set_v1" "rustfs" {
  count = var.enable_rustfs ? 1 : 0

  metadata {
    name      = "rustfs"
    namespace = local.ds_ns
    labels    = { app = "rustfs", "managed-by" = "terraform" }
  }

  spec {
    service_name = "rustfs"
    replicas     = 1

    selector { match_labels = { app = "rustfs" } }

    template {
      metadata { labels = { app = "rustfs" } }

      spec {
        # Newly provisioned longhorn volumes are root-owned; run as root and set
        # fsGroup so RustFS can write to /data (and its in-image /logs).
        security_context {
          run_as_user  = 0
          run_as_group = 0
          fs_group     = 0
        }

        container {
          name  = "rustfs"
          image = "${var.image_registry}rustfs/rustfs:latest"
          args  = ["/data"]

          port {
            name           = "s3"
            container_port = 9000
          }
          port {
            name           = "console"
            container_port = 9001
          }

          env {
            name  = "RUSTFS_VOLUMES"
            value = "/data"
          }
          env {
            name  = "RUSTFS_ADDRESS"
            value = ":9000"
          }
          env {
            name  = "RUSTFS_CONSOLE_ADDRESS"
            value = ":9001"
          }
          env {
            name  = "RUSTFS_CONSOLE_ENABLE"
            value = "true"
          }
          env {
            name = "RUSTFS_ACCESS_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.rustfs[0].metadata[0].name
                key  = "access-key"
              }
            }
          }
          env {
            name = "RUSTFS_SECRET_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.rustfs[0].metadata[0].name
                key  = "secret-key"
              }
            }
          }

          resources {
            requests = { cpu = var.rustfs_resources.requests_cpu, memory = var.rustfs_resources.requests_memory }
            limits   = { cpu = var.rustfs_resources.limits_cpu, memory = var.rustfs_resources.limits_memory }
          }

          volume_mount {
            name       = "data"
            mount_path = "/data"
          }
        }
      }
    }

    volume_claim_template {
      metadata { name = "data" }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = var.storage_class
        resources { requests = { storage = var.rustfs_storage_size } }
      }
    }
  }
}

resource "kubernetes_service_v1" "rustfs" {
  count = var.enable_rustfs ? 1 : 0

  metadata {
    name      = "rustfs"
    namespace = local.ds_ns
    labels    = { app = "rustfs" }
  }

  spec {
    selector = { app = "rustfs" }

    port {
      name        = "s3"
      port        = 9000
      target_port = 9000
    }
    port {
      name        = "console"
      port        = 9001
      target_port = 9001
    }
  }
}

# Create the bucket once RustFS is up, using a tiny S3 client Job (idempotent:
# `mb` on an existing bucket is ignored with || true).
resource "kubernetes_job_v1" "rustfs_bucket" {
  count = var.enable_rustfs ? 1 : 0

  metadata {
    name      = "rustfs-create-bucket"
    namespace = local.ds_ns
  }

  spec {
    backoff_limit = 6

    template {
      metadata { labels = { app = "rustfs-init" } }

      spec {
        restart_policy = "OnFailure"

        container {
          name    = "mc"
          image   = "${var.image_registry}minio/mc:latest"
          command = ["/bin/sh", "-c"]
          args = [
            <<-EOT
            set -e
            until mc alias set rfs http://rustfs:9000 "$ACCESS_KEY" "$SECRET_KEY"; do
              echo "waiting for rustfs..."; sleep 3;
            done
            mc mb --ignore-existing rfs/${var.rustfs_bucket}
            echo "bucket ${var.rustfs_bucket} ready"
            EOT
          ]

          env {
            name = "ACCESS_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.rustfs[0].metadata[0].name
                key  = "access-key"
              }
            }
          }
          env {
            name = "SECRET_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.rustfs[0].metadata[0].name
                key  = "secret-key"
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_stateful_set_v1.rustfs]

  wait_for_completion = false
}
