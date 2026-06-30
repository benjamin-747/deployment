variable "namespace" {
  type        = string
  description = "Namespace the gitmono stack is deployed into."
}

variable "ingress_class_name" {
  type        = string
  description = "IngressClass to use. k3s ships Traefik as 'traefik' by default."
  default     = "traefik"
}

variable "base_domain" {
  type        = string
  description = "Base domain for per-app subdomains; each app Ingress matches '<prefix>.<base_domain>'."
  default     = "xuanwu.openatom.cn"
}

variable "app_subdomains" {
  type        = map(string)
  description = "Primary subdomain prefix per app (key = app name). Host becomes '<prefix>.<base_domain>'."
  default = {
    "mono-engine"   = "git"
    "mega-ui"       = "app"
    "mega-web-sync" = "sync"
    "orion-server"  = "orion"
    "campsite-api"  = "api"
  }
}

variable "app_alias_subdomains" {
  type        = map(list(string))
  description = "Extra subdomain prefixes that share an app's Service (e.g. campsite-api also serves auth.<base_domain>)."
  default = {
    "campsite-api" = ["auth"]
  }
}

variable "cors_allowed_origins" {
  type        = list(string)
  description = "Origins for MEGA_OAUTH__ALLOWED_CORS_ORIGINS on mono-engine / orion-server. Joined with commas into the env var. Empty = just the mega-ui public URL (https://<app>.<base_domain>)."
  default     = []
}

variable "cratespro_url" {
  type        = string
  description = "Public URL for cratespro (NEXT_PUBLIC_CRATES_PRO_URL). Shared across all onprem environments."
  default     = "https://cratespro.xuanwu.openatom.cn"
}

# ---------------------------------------------------------------------------
# gitmono application stack (mirrors envs/tencentcloud/buck2hub.com)
# ---------------------------------------------------------------------------

variable "enable_apps" {
  type        = bool
  description = "Deploy the 5 gitmono services (mono-engine, mega-ui, mega-web-sync, orion-server, campsite-api)."
  default     = true
}

variable "image_repo_base" {
  type        = string
  description = "Base container image repo for the gitmono services."
  default     = "public.ecr.aws/m8q5m4u3/mega"
}

variable "image_tag" {
  type        = string
  description = "Default image tag for the gitmono services (and the mega-init fallback). Override a single service with var.app_images."
  default     = "latest"
}

variable "app_images" {
  type        = map(string)
  description = "Per-app full image override (keys: mono-engine, mega-ui, mega-web-sync, orion-server, campsite-api). Empty/unset falls back to '<image_repo_base>/<repo>:<image_tag>'."
  default     = {}
}

variable "db_url" {
  type        = string
  description = "Override PostgreSQL URL for mono-engine / orion-server. Leave empty to auto-build from the in-cluster postgresql Helm release."
  default     = ""
}

# ---------------------------------------------------------------------------
# Mega post-deploy initialization (scripts/init_mega/init_mega.py)
# ---------------------------------------------------------------------------

variable "enable_mega_init" {
  type        = bool
  description = "Run the one-time mega-init Job after deploy (imports buckal-bundles + libra deps via the mono-engine API). Off by default because it git-pushes and clones from GitHub."
  default     = false
}

variable "mega_init_image" {
  type        = string
  description = "Image for the mega-init Job; must contain python3, git and the scripts/ dir. Empty = '<image_repo_base>/mega-init:latest'."
  default     = ""
}

variable "mega_init_args" {
  type        = list(string)
  description = "Extra args appended to init_mega.py (e.g. [\"--skip-libra\"] or [\"--skip-buckal\"])."
  default     = []
}

variable "redis_url" {
  type        = string
  description = "Override Redis URL for mono-engine. Leave empty to auto-build from the in-cluster redis Helm release."
  default     = ""
}

variable "mysql_url" {
  type        = string
  description = "Override MySQL URL for campsite-api (DATABASE_URL). Leave empty to auto-build from the in-cluster mysql Helm release."
  default     = ""
}

# ---------------------------------------------------------------------------
# In-cluster datastores (Helm / Bitnami)
# ---------------------------------------------------------------------------

variable "storage_class" {
  type        = string
  description = "StorageClass for database PVCs. The cluster has longhorn (distributed) and local-path."
  default     = "longhorn"
}

variable "image_registry" {
  type        = string
  description = "Optional image registry prefix for datastore images (e.g. a mirror). Empty = Docker Hub default."
  default     = ""
}

# ---------------------------------------------------------------------------
# RustFS — S3-compatible object storage (replaces external S3 / COS)
# ---------------------------------------------------------------------------

variable "enable_rustfs" {
  type        = bool
  description = "Deploy RustFS (S3-compatible object storage) and auto-wire it as the S3 backend for the apps."
  default     = true
}

variable "rustfs_access_key" {
  type        = string
  description = "RustFS root access key. Set in terraform.tfvars; do not rely on a weak default for the public console."

  validation {
    condition     = length(trimspace(var.rustfs_access_key)) > 0
    error_message = "rustfs_access_key must not be empty."
  }
}

variable "rustfs_secret_key" {
  type        = string
  description = "RustFS root secret key. Set in terraform.tfvars; do not rely on a weak default for the public console."
  sensitive   = true

  validation {
    condition     = length(trimspace(var.rustfs_secret_key)) > 0
    error_message = "rustfs_secret_key must not be empty."
  }
}

variable "rustfs_bucket" {
  type        = string
  description = "Bucket created in RustFS and used by mono-engine / orion-server."
  default     = "buck2hub-assets"
}

variable "rustfs_region" {
  type        = string
  description = "Region advertised to S3 clients (RustFS ignores it, but the S3 SDK requires a non-empty value)."
  default     = "us-east-1"
}

variable "rustfs_storage_size" {
  type        = string
  description = "RustFS data PVC size."
  default     = "20Gi"
}

variable "enable_rustfs_console_ingress" {
  type        = bool
  description = "Expose the RustFS web console (:9001) publicly via a Traefik Ingress at '<rustfs_console_subdomain>.<base_domain>'. Requires enable_rustfs."
  default     = true
}

variable "rustfs_console_subdomain" {
  type        = string
  description = "Subdomain prefix for the RustFS console Ingress host ('<prefix>.<base_domain>')."
  default     = "rustfs"
}

variable "rustfs_resources" {
  type = object({
    requests_cpu    = string
    requests_memory = string
    limits_cpu      = string
    limits_memory   = string
  })
  description = "RustFS container resource requests/limits."
  default = {
    requests_cpu    = "250m"
    requests_memory = "512Mi"
    limits_cpu      = "1000m"
    limits_memory   = "1Gi"
  }
}

variable "enable_postgresql" {
  type        = bool
  description = "Deploy PostgreSQL via Bitnami Helm chart in the app namespace."
  default     = true
}

variable "pg_username" {
  type        = string
  description = "PostgreSQL application user."
  default     = "gitmega"
}

variable "pg_password" {
  type        = string
  description = "PostgreSQL application user password."
  default     = "Buck2Hub#2026"
  sensitive   = true
}

variable "pg_database" {
  type        = string
  description = "PostgreSQL database name."
  default     = "buck2hub"
}

variable "pg_storage_size" {
  type        = string
  description = "PostgreSQL PVC size."
  default     = "10Gi"
}

variable "pg_resources" {
  type = object({
    requests_cpu    = string
    requests_memory = string
    limits_cpu      = string
    limits_memory   = string
  })
  description = "PostgreSQL container resource requests/limits."
  default = {
    requests_cpu    = "250m"
    requests_memory = "512Mi"
    limits_cpu      = "1000m"
    limits_memory   = "1Gi"
  }
}

variable "enable_mysql" {
  type        = bool
  description = "Deploy MySQL via Bitnami Helm chart in the app namespace (campsite-api / Rails)."
  default     = true
}

variable "mysql_root_password" {
  type        = string
  description = "MySQL root password."
  default     = "Buck2Hub#2026"
  sensitive   = true
}

variable "mysql_username" {
  type        = string
  description = "MySQL application user."
  default     = "gitmega"
}

variable "mysql_password" {
  type        = string
  description = "MySQL application user password."
  default     = "Buck2Hub#2026"
  sensitive   = true
}

variable "mysql_database" {
  type        = string
  description = "MySQL database name for campsite-api."
  default     = "campsite"
}

variable "mysql_storage_size" {
  type        = string
  description = "MySQL PVC size."
  default     = "10Gi"
}

variable "mysql_resources" {
  type = object({
    requests_cpu    = string
    requests_memory = string
    limits_cpu      = string
    limits_memory   = string
  })
  description = "MySQL container resource requests/limits."
  default = {
    requests_cpu    = "250m"
    requests_memory = "512Mi"
    limits_cpu      = "1000m"
    limits_memory   = "1Gi"
  }
}

variable "enable_redis" {
  type        = bool
  description = "Deploy Redis via Bitnami Helm chart in the app namespace."
  default     = true
}

variable "redis_password" {
  type        = string
  description = "Redis password."
  default     = "Buck2Hub#2026"
  sensitive   = true
}

variable "redis_storage_size" {
  type        = string
  description = "Redis PVC size."
  default     = "2Gi"
}

variable "redis_resources" {
  type = object({
    requests_cpu    = string
    requests_memory = string
    limits_cpu      = string
    limits_memory   = string
  })
  description = "Redis container resource requests/limits."
  default = {
    requests_cpu    = "100m"
    requests_memory = "256Mi"
    limits_cpu      = "500m"
    limits_memory   = "512Mi"
  }
}

variable "s3_access_key" {
  type        = string
  description = "S3-compatible object storage access key id."
  default     = ""
}

variable "s3_secret_key" {
  type        = string
  description = "S3-compatible object storage secret access key."
  default     = ""
  sensitive   = true
}

variable "s3_bucket" {
  type        = string
  description = "S3-compatible object storage bucket name."
  default     = ""
}

variable "s3_region" {
  type        = string
  description = "S3-compatible object storage region."
  default     = ""
}

variable "s3_endpoint" {
  type        = string
  description = "S3-compatible object storage endpoint URL."
  default     = ""
}

variable "rails_env" {
  type        = string
  description = "RAILS_ENV for campsite-api."
  default     = "production"
}

variable "rails_master_key" {
  type        = string
  description = "RAILS_MASTER_KEY for campsite-api."
  default     = ""
  sensitive   = true
}

variable "app_resources" {
  type = map(object({
    cpu      = string
    memory   = string
    replicas = number
  }))
  description = "Per-service cpu/memory/replicas override (keys: mono-engine, mega-ui, mega-web-sync, orion-server, campsite-api). cpu/memory are applied as both requests and limits. Overriding a key replaces its whole object, so supply all fields."
  default     = {}
}
