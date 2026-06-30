# In-cluster PostgreSQL / MySQL / Redis as StatefulSets (official images).
# Bitnami Helm charts were dropped: cluster nodes cannot pull docker.io/bitnami/*
# reliably (timeout / mirror 403). Service names match apps.tf connection strings.

locals {
  ds_ns = kubernetes_namespace_v1.this.metadata[0].name
}

# ---------------------------------------------------------------------------
# PostgreSQL
# ---------------------------------------------------------------------------

resource "kubernetes_secret_v1" "postgresql" {
  count = var.enable_postgresql ? 1 : 0

  metadata {
    name      = "postgresql-auth"
    namespace = local.ds_ns
  }

  data = {
    username = var.pg_username
    password = var.pg_password
    database = var.pg_database
  }
}

resource "kubernetes_stateful_set_v1" "postgresql" {
  count = var.enable_postgresql ? 1 : 0

  metadata {
    name      = "postgresql"
    namespace = local.ds_ns
    labels    = { app = "postgresql", "managed-by" = "terraform" }
  }

  spec {
    service_name = "postgresql"
    replicas     = 1

    selector { match_labels = { app = "postgresql" } }

    template {
      metadata { labels = { app = "postgresql" } }

      spec {
        container {
          name  = "postgresql"
          image = "${var.image_registry}postgres:16-alpine"

          port { container_port = 5432 }

          env {
            name  = "POSTGRES_USER"
            value = var.pg_username
          }
          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.postgresql[0].metadata[0].name
                key  = "password"
              }
            }
          }
          env {
            name  = "POSTGRES_DB"
            value = var.pg_database
          }

          resources {
            requests = { cpu = var.pg_resources.requests_cpu, memory = var.pg_resources.requests_memory }
            limits   = { cpu = var.pg_resources.limits_cpu, memory = var.pg_resources.limits_memory }
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
            sub_path   = "pgdata"
          }
        }
      }
    }

    volume_claim_template {
      metadata { name = "data" }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = var.storage_class
        resources { requests = { storage = var.pg_storage_size } }
      }
    }
  }
}

resource "kubernetes_service_v1" "postgresql" {
  count = var.enable_postgresql ? 1 : 0

  metadata {
    name      = "postgresql"
    namespace = local.ds_ns
    labels    = { app = "postgresql" }
  }

  spec {
    selector = { app = "postgresql" }
    port {
      port        = 5432
      target_port = 5432
    }
  }
}

# ---------------------------------------------------------------------------
# MySQL
# ---------------------------------------------------------------------------

resource "kubernetes_secret_v1" "mysql" {
  count = var.enable_mysql ? 1 : 0

  metadata {
    name      = "mysql-auth"
    namespace = local.ds_ns
  }

  data = {
    root-password = var.mysql_root_password
    username      = var.mysql_username
    password      = var.mysql_password
    database      = var.mysql_database
  }
}

resource "kubernetes_stateful_set_v1" "mysql" {
  count = var.enable_mysql ? 1 : 0

  metadata {
    name      = "mysql"
    namespace = local.ds_ns
    labels    = { app = "mysql", "managed-by" = "terraform" }
  }

  spec {
    service_name = "mysql"
    replicas     = 1

    selector { match_labels = { app = "mysql" } }

    template {
      metadata { labels = { app = "mysql" } }

      spec {
        container {
          name  = "mysql"
          image = "${var.image_registry}mysql:8.4"

          port { container_port = 3306 }

          env {
            name = "MYSQL_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.mysql[0].metadata[0].name
                key  = "root-password"
              }
            }
          }
          env {
            name  = "MYSQL_DATABASE"
            value = var.mysql_database
          }
          env {
            name = "MYSQL_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.mysql[0].metadata[0].name
                key  = "username"
              }
            }
          }
          env {
            name = "MYSQL_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.mysql[0].metadata[0].name
                key  = "password"
              }
            }
          }

          resources {
            requests = { cpu = var.mysql_resources.requests_cpu, memory = var.mysql_resources.requests_memory }
            limits   = { cpu = var.mysql_resources.limits_cpu, memory = var.mysql_resources.limits_memory }
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/mysql"
          }
        }
      }
    }

    volume_claim_template {
      metadata { name = "data" }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = var.storage_class
        resources { requests = { storage = var.mysql_storage_size } }
      }
    }
  }
}

resource "kubernetes_service_v1" "mysql" {
  count = var.enable_mysql ? 1 : 0

  metadata {
    name      = "mysql"
    namespace = local.ds_ns
    labels    = { app = "mysql" }
  }

  spec {
    selector = { app = "mysql" }
    port {
      port        = 3306
      target_port = 3306
    }
  }
}

# ---------------------------------------------------------------------------
# Redis  (service name redis-master matches apps.tf local.redis_host)
# ---------------------------------------------------------------------------

resource "kubernetes_secret_v1" "redis" {
  count = var.enable_redis ? 1 : 0

  metadata {
    name      = "redis-auth"
    namespace = local.ds_ns
  }

  data = { password = var.redis_password }
}

resource "kubernetes_stateful_set_v1" "redis" {
  count = var.enable_redis ? 1 : 0

  metadata {
    name      = "redis-master"
    namespace = local.ds_ns
    labels    = { app = "redis", "managed-by" = "terraform" }
  }

  spec {
    service_name = "redis-master"
    replicas     = 1

    selector { match_labels = { app = "redis" } }

    template {
      metadata { labels = { app = "redis" } }

      spec {
        container {
          name  = "redis"
          image = "${var.image_registry}redis:7.2-alpine"

          port { container_port = 6379 }

          command = ["/bin/sh", "-c", "exec redis-server --requirepass \"$$REDIS_PASSWORD\""]

          env {
            name = "REDIS_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.redis[0].metadata[0].name
                key  = "password"
              }
            }
          }

          resources {
            requests = { cpu = var.redis_resources.requests_cpu, memory = var.redis_resources.requests_memory }
            limits   = { cpu = var.redis_resources.limits_cpu, memory = var.redis_resources.limits_memory }
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
        resources { requests = { storage = var.redis_storage_size } }
      }
    }
  }
}

resource "kubernetes_service_v1" "redis" {
  count = var.enable_redis ? 1 : 0

  metadata {
    name      = "redis-master"
    namespace = local.ds_ns
    labels    = { app = "redis" }
  }

  spec {
    selector = { app = "redis" }
    port {
      port        = 6379
      target_port = 6379
    }
  }
}
