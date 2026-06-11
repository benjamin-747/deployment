# The 5 gitmono services, ported from envs/tencentcloud/buck2hub.com. The cloud
# stack pointed these at Tencent Cloud PostgreSQL / Redis / COS; here the backend
# endpoints come from variables (db_url / redis_url / s3_*), so set them in
# terraform.tfvars before the stateful services (mono-engine / orion-server /
# campsite-api) can become healthy. Inter-service traffic uses in-cluster DNS.

locals {
  app_ns = kubernetes_namespace_v1.demo.metadata[0].name

  # In-cluster service URLs (<svc>.<ns>.svc.cluster.local).
  mono_url     = "http://mono-engine.${var.namespace}.svc.cluster.local:8000"
  orion_url    = "http://orion-server.${var.namespace}.svc.cluster.local:8004"
  campsite_url = "http://campsite-api.${var.namespace}.svc.cluster.local:8080"

  pg_host    = "postgresql.${var.namespace}.svc.cluster.local"
  mysql_host = "mysql.${var.namespace}.svc.cluster.local"
  redis_host = "redis-master.${var.namespace}.svc.cluster.local"

  # Public subdomain per app: "<prefix>.<base_domain>".
  app_hosts  = { for k, prefix in var.app_subdomains : k => "${prefix}.${var.base_domain}" }
  ui_public  = "https://${local.app_hosts["mega-ui"]}"
  api_public = "https://${local.app_hosts["campsite-api"]}"

  # Extra aliases that share an app's Service (e.g. campsite-api also serves auth.*).
  app_alias_hosts = {
    for k, prefixes in var.app_alias_subdomains : k => [for p in prefixes : "${p}.${var.base_domain}"]
  }

  # All hostnames each app's Ingress should match (primary + aliases).
  app_ingress_hosts = {
    for k in keys(local.apps) : k => concat([local.app_hosts[k]], lookup(local.app_alias_hosts, k, []))
  }

  # Auto-build connection strings from Helm releases unless overridden.
  db_url = var.db_url != "" ? var.db_url : (
    var.enable_postgresql
    ? "postgres://${var.pg_username}:${urlencode(var.pg_password)}@${local.pg_host}:5432/${var.pg_database}?sslmode=disable"
    : ""
  )

  redis_url = var.redis_url != "" ? var.redis_url : (
    var.enable_redis
    ? "redis://:${urlencode(var.redis_password)}@${local.redis_host}:6379"
    : ""
  )

  mysql_url = var.mysql_url != "" ? var.mysql_url : (
    var.enable_mysql
    ? "mysql://${var.mysql_username}:${urlencode(var.mysql_password)}@${local.mysql_host}:3306/${var.mysql_database}"
    : ""
  )

  # Image for the mega-init Job (needs python3 + git + the scripts/ dir).
  mega_init_image = var.mega_init_image != "" ? var.mega_init_image : "${var.image_repo_base}/mega-init:latest"

  rustfs_endpoint = "http://rustfs.${var.namespace}.svc.cluster.local:9000"

  # Effective S3 settings: explicit s3_* vars win, otherwise fall back to the
  # in-cluster RustFS deployment (path-style; bucket name resolves in-cluster DNS).
  s3_access_key = var.s3_access_key != "" ? var.s3_access_key : (var.enable_rustfs ? var.rustfs_access_key : "")
  s3_secret_key = var.s3_secret_key != "" ? var.s3_secret_key : (var.enable_rustfs ? var.rustfs_secret_key : "")
  s3_bucket     = var.s3_bucket != "" ? var.s3_bucket : (var.enable_rustfs ? var.rustfs_bucket : "")
  s3_region     = var.s3_region != "" ? var.s3_region : (var.enable_rustfs ? var.rustfs_region : "")
  s3_endpoint   = var.s3_endpoint != "" ? var.s3_endpoint : (var.enable_rustfs ? local.rustfs_endpoint : "")

  s3_env = [
    { name = "MEGA_OBJECT_STORAGE__S3__ACCESS_KEY_ID", value = local.s3_access_key },
    { name = "MEGA_OBJECT_STORAGE__S3__SECRET_ACCESS_KEY", value = local.s3_secret_key },
    { name = "MEGA_OBJECT_STORAGE__S3__BUCKET", value = local.s3_bucket },
    { name = "MEGA_OBJECT_STORAGE__S3__REGION", value = local.s3_region },
    { name = "MEGA_OBJECT_STORAGE__S3__ENDPOINT_URL", value = local.s3_endpoint },
    { name = "MEGA_OBJECT_STORAGE__STORAGE_TYPE", value = "s3compatible" },
  ]

  # Per-app requests/limits. Unlike TKE super nodes (requests == limits), k3s
  # allows overcommit, so requests and limits are independent. Defaults keep
  # requests == limits; override per app via var.app_resources in tfvars.
  app_resources_default = {
    "mono-engine"   = { requests_cpu = "500m", requests_memory = "1024Mi", limits_cpu = "500m", limits_memory = "1024Mi", replicas = 1 }
    "mega-ui"       = { requests_cpu = "250m", requests_memory = "512Mi", limits_cpu = "250m", limits_memory = "512Mi", replicas = 1 }
    "mega-web-sync" = { requests_cpu = "250m", requests_memory = "512Mi", limits_cpu = "250m", limits_memory = "512Mi", replicas = 1 }
    "orion-server"  = { requests_cpu = "250m", requests_memory = "512Mi", limits_cpu = "250m", limits_memory = "512Mi", replicas = 1 }
    "campsite-api"  = { requests_cpu = "500m", requests_memory = "1024Mi", limits_cpu = "500m", limits_memory = "1024Mi", replicas = 1 }
  }
  res = merge(local.app_resources_default, var.app_resources)

  apps = {
    "mono-engine" = {
      image          = "${var.image_repo_base}/mono-engine:latest"
      container_port = 8000
      environment = concat([
        { name = "MEGA_LOG__LEVEL", value = "info" },
        { name = "MEGA_LOG__WITH_ANSI", value = "false" },
        { name = "MEGA_AUTHENTICATION__ENABLE_HTTP_PUSH", value = "true" },
        { name = "MEGA_BUILD__ENABLE_BUILD", value = "true" },
        { name = "MEGA_DATABASE__DB_URL", value = local.db_url },
        { name = "MEGA_BUILD__ORION_SERVER", value = local.orion_url },
        { name = "MEGA_OAUTH__CAMPSITE_API_DOMAIN", value = local.campsite_url },
        { name = "MEGA_OAUTH__ALLOWED_CORS_ORIGINS", value = local.ui_public },
        { name = "MEGA_REDIS__URL", value = local.redis_url },
      ], local.s3_env)
    }
    "mega-ui" = {
      image          = "${var.image_repo_base}/mega-ui:latest"
      container_port = 3000
      environment = [
        { name = "NEXT_PUBLIC_API_URL", value = "https://api.xuanwu.openatom.cn" },
        { name = "NEXT_PUBLIC_INTERNAL_API_URL", value = local.campsite_url },
        { name = "NEXT_PUBLIC_MONO_API_URL", value = "https://git.xuanwu.openatom.cn" },
        { name = "NEXT_PUBLIC_ORION_API_URL", value = "https://orion.xuanwu.openatom.cn" },
        { name = "NEXT_PUBLIC_AUTH_URL", value = "https://auth.xuanwu.openatom.cn" },
        { name = "NEXT_PUBLIC_WEB_URL", value = "https://app.xuanwu.openatom.cn" },
        { name = "NEXT_PUBLIC_SYNC_URL", value = "wss://sync.xuanwu.openatom.cn" },
        { name = "NEXT_PUBLIC_CRATES_PRO_URL", value = "https://cratespro.xuanwu.openatom.cn" },
      ]
    }
    "mega-web-sync" = {
      image          = "${var.image_repo_base}/web-sync-server:latest"
      container_port = 9000
      environment = [
        { name = "API_URL", value = local.api_public },
        { name = "NODE_ENV", value = "production" },
      ]
    }
    "orion-server" = {
      image          = "${var.image_repo_base}/orion-server:latest"
      container_port = 8004
      environment = concat([
        { name = "MEGA_ORION_SERVER__DB_URL", value = local.db_url },
        { name = "MEGA_ORION_SERVER__MONOBASE_URL", value = local.mono_url },
        { name = "MEGA_OAUTH__ALLOWED_CORS_ORIGINS", value = local.ui_public },
      ], local.s3_env)
    }
    "campsite-api" = {
      image          = "${var.image_repo_base}/campsite-api:latest"
      container_port = 8080
      environment = [
        { name = "DEV_APP_URL", value = local.ui_public },
        { name = "PORT", value = "8080" },
        { name = "RAILS_ENV", value = var.rails_env },
        { name = "RAILS_MASTER_KEY", value = var.rails_master_key },
        { name = "SERVER_COMMAND", value = "bundle exec puma" },
      ]
    }
  }
}

module "apps" {
  source   = "../../../modules/compute/kubernetes/k8s_app"
  for_each = var.enable_apps ? local.apps : {}

  depends_on = [
    kubernetes_stateful_set_v1.postgresql,
    kubernetes_stateful_set_v1.mysql,
    kubernetes_stateful_set_v1.redis,
    kubernetes_stateful_set_v1.rustfs,
  ]

  name            = each.key
  namespace       = local.app_ns
  image           = each.value.image
  container_port  = each.value.container_port
  replicas        = local.res[each.key].replicas
  requests_cpu    = local.res[each.key].requests_cpu
  requests_memory = local.res[each.key].requests_memory
  limits_cpu      = local.res[each.key].limits_cpu
  limits_memory   = local.res[each.key].limits_memory
  environment     = each.value.environment
  service_type    = "ClusterIP"
}

# One-time schema bootstrap for campsite-api. Runs `bin/rails db:create`
# followed by `bin/rails db:migrate` so every migration file is actually
# executed (including data migrations like the Mega organization seed). Using
# db:migrate instead of db:prepare avoids the schema-load path, which only
# stamps schema_migrations and would skip the data-migration INSERTs.
# Connection details come from the Rails encrypted credentials (decrypted with
# RAILS_MASTER_KEY), so it reuses the app's env. The completed Job is kept
# around so re-running `apply` is a no-op; bump the image (or taint this
# resource) to re-run after new migrations ship.
resource "kubernetes_job_v1" "campsite_db_prepare" {
  count = var.enable_apps && var.enable_mysql ? 1 : 0

  metadata {
    name      = "campsite-api-db-prepare"
    namespace = local.app_ns
    labels    = { app = "campsite-api", "managed-by" = "terraform" }
  }

  spec {
    backoff_limit = 3

    template {
      metadata {
        labels = { app = "campsite-api", job = "db-prepare" }
      }

      spec {
        restart_policy = "Never"

        container {
          name    = "db-prepare"
          image   = local.apps["campsite-api"].image
          command = ["sh", "-c", "bin/rails db:create && bin/rails db:migrate"]

          dynamic "env" {
            for_each = local.apps["campsite-api"].environment
            content {
              name  = env.value.name
              value = env.value.value
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_stateful_set_v1.mysql]

  wait_for_completion = true

  timeouts {
    create = "10m"
    update = "10m"
  }
}

# One-time Mega bootstrap. Runs scripts/init_mega/init_mega.py against the
# in-cluster mono-engine API: it imports buckal-bundles into the toolchains repo
# (commit + push + merge the CL) and imports libra's Buck2 deps. This is a
# runtime/post-deploy step (it waits for /api/v1/status and talks to the live
# server), which is why it belongs in a Job rather than the Dockerfile.
#
# Requirements / caveats:
#   - var.mega_init_image must contain python3, git and the scripts/ directory.
#   - The pod needs egress to GitHub (clones buckal-bundles + libra).
#   - mono-engine has ENABLE_HTTP_PUSH=true, so the git push is anonymous; if
#     that changes, wire push credentials into this Job.
#   - Re-pushing the same buckal-bundles content creates a new CL, so this is
#     gated behind var.enable_mega_init (off by default). Taint to re-run.
resource "kubernetes_job_v1" "mega_init" {
  count = var.enable_apps && var.enable_mega_init ? 1 : 0

  metadata {
    name      = "mega-init"
    namespace = local.app_ns
    labels    = { app = "mega-init", "managed-by" = "terraform" }
  }

  spec {
    backoff_limit = 3

    template {
      metadata {
        labels = { app = "mega-init", job = "mega-init" }
      }

      spec {
        restart_policy = "Never"

        # Co-locate with mono-engine: cross-node pod->ClusterIP traffic to
        # mono-engine has proven flaky here, and the script's git clone/push
        # don't retry. Scheduling on the same node keeps the git HTTP traffic
        # node-local. (Pod label is app=mega-init so this targets mono-engine,
        # not itself.)
        affinity {
          pod_affinity {
            required_during_scheduling_ignored_during_execution {
              label_selector {
                match_expressions {
                  key      = "app"
                  operator = "In"
                  values   = ["mono-engine"]
                }
              }
              topology_key = "kubernetes.io/hostname"
            }
          }
        }

        container {
          name    = "mega-init"
          image   = local.mega_init_image
          command = concat(["python3", "scripts/init_mega/init_mega.py", "--base-url", local.mono_url], var.mega_init_args)
        }
      }
    }
  }

  # mono-engine must exist before init runs; the script itself polls
  # /api/v1/status until the server is actually ready.
  depends_on = [module.apps]

  wait_for_completion = true

  timeouts {
    create = "30m"
    update = "30m"
  }
}

# One Traefik Ingress per app, routing its public subdomain to the app Service.
# Served on both the http (web) and https (websecure) entrypoints so the upstream
# 玄武 gateway (which forwards over https) reaches them.
resource "kubernetes_ingress_v1" "apps" {
  for_each = var.enable_apps ? local.apps : {}

  metadata {
    name      = each.key
    namespace = local.app_ns
    labels    = { app = each.key, "managed-by" = "terraform" }
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "web,websecure"
    }
  }

  # k3s/Rancher injects this annotation at runtime; ignore it to avoid a
  # perpetual diff on every plan.
  lifecycle {
    ignore_changes = [metadata[0].annotations["field.cattle.io/publicEndpoints"]]
  }

  spec {
    ingress_class_name = var.ingress_class_name

    dynamic "rule" {
      for_each = local.app_ingress_hosts[each.key]

      content {
        host = rule.value

        http {
          path {
            path      = "/"
            path_type = "Prefix"

            backend {
              service {
                name = module.apps[each.key].service_name
                port {
                  number = each.value.container_port
                }
              }
            }
          }
        }
      }
    }
  }
}
