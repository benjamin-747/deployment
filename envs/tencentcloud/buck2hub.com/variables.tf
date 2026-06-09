# --- Core ---
variable "region" {
  type        = string
  description = "Tencent Cloud region (e.g. ap-guangzhou, ap-singapore)"
}

variable "base_domain" {
  type        = string
  description = "Public app domain (no scheme), e.g. buck2hub.com"
}

variable "app_suffix" {
  type        = string
  description = "Prefix for resource names"
}

variable "default_tags" {
  type        = map(string)
  description = "Tags applied to resources created by this environment"
  default     = {}
}

# --- Credentials (sensitive) ---
variable "tencentcloud_secret_id" {
  type        = string
  description = "Tencent Cloud API SecretId"
  sensitive   = true
}

variable "tencentcloud_secret_key" {
  type        = string
  description = "Tencent Cloud API SecretKey"
  sensitive   = true
}

# --- Network ---
variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDR blocks"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

# --- Database ---
variable "db_username" {
  type        = string
  description = "PostgreSQL master username"
  sensitive   = true
}

variable "db_password" {
  type        = string
  description = "PostgreSQL master password"
  sensitive   = true
}

variable "db_schema" {
  type        = string
  description = "Default database name"
}

variable "db_cpu" {
  type        = number
  description = "PostgreSQL CPU cores (0 = auto-select based on memory)"
  default     = 1
}

variable "db_memory" {
  type        = number
  description = "PostgreSQL memory size in GB"
  default     = 2
}

variable "db_storage" {
  type        = number
  description = "PostgreSQL storage size in GB (multiple of 10)"
  default     = 20
}

# --- Object storage ---
variable "cos_bucket" {
  type        = string
  description = "COS bucket name prefix (APPID appended automatically)"
}

# --- Cache ---
variable "redis_password" {
  type        = string
  description = "Redis auth password (8-16 chars, mixed case + digits)"
  sensitive   = true
}

variable "redis_mem_size" {
  type        = number
  description = "Redis memory size in MB"
  default     = 1024
}

variable "redis_type_id" {
  type        = number
  description = "Redis product version / architecture. 19 = Valkey 8.0 standard, 20 = Valkey 8.0 cluster, 15 = Redis 6.2 standard."
  default     = 19
}

# --- TKE Serverless services (for the follow-up Kubernetes manifest layer) ---
variable "services" {
  type = map(object({
    image  = string
    port   = number
    host   = string
    cpu    = string
    memory = string
    environment = list(object({
      name  = string
      value = string
    }))
  }))
  description = "Per-service workload definitions for TKE Serverless"
  default     = {}
}

# --- Compute mode ---
variable "enable_eksci" {
  type        = bool
  description = "Deploy all gitmono services via EKSCI container instances. CLB host rules route to each instance private IP."
  default     = true
}

variable "image_repo_base" {
  type        = string
  description = "Base image repository for gitmono services (without the trailing service name)."
  default     = "public.ecr.aws/m8q5m4u3/mega"
}

variable "ui_env" {
  type        = string
  description = "Image tag prefix for the mega-ui image (tag = <ui_env>-latest)."
  default     = "gitmono"
}

variable "rails_env" {
  type        = string
  description = "RAILS_ENV for the campsite-api service"
  default     = "staging-gitmono"
}

variable "rails_master_key" {
  type        = string
  description = "RAILS_MASTER_KEY for the campsite-api service"
  sensitive   = true
  default     = ""
}

variable "workload_resources" {
  type = map(object({
    cpu      = string
    memory   = string
    replicas = number
  }))
  description = "Per-service pod resources (cpu/memory as K8s quantities, replicas). Overrides the built-in defaults per service key."
  default     = {}
}

variable "enable_pod_eip" {
  type        = bool
  description = "Attach a public EIP to every gitmono pod (internet egress on TKE super nodes)."
  default     = true
}

variable "pod_eip_bandwidth" {
  type        = number
  description = "Per-pod EIP outbound bandwidth cap in Mbps."
  default     = 100
}

# --- SSL (CLB HTTPS) ---
variable "ssl_create_mode" {
  type        = string
  description = "SSL certificate source: upload (wildcard PEM), free (single-domain DV), existing (console cert ID), or disabled (HTTP only)."
  default     = "upload"

  validation {
    condition     = contains(["free", "upload", "existing", "disabled"], var.ssl_create_mode)
    error_message = "ssl_create_mode must be one of: free, upload, existing, disabled."
  }
}

variable "ssl_domain" {
  type        = string
  description = "Certificate domain. Defaults to *.<base_domain> (wildcard for all public hostnames)."
  default     = null
}

variable "ssl_certificate_pem_file" {
  type        = string
  description = "Path to PEM certificate chain file when ssl_create_mode is upload (relative to this env directory)."
  default     = "certs/fullchain.pem"
}

variable "ssl_private_key_pem_file" {
  type        = string
  description = "Path to PEM private key file when ssl_create_mode is upload (relative to this env directory)."
  default     = "certs/privkey.pem"
}

variable "ssl_certificate_id" {
  type        = string
  description = "Existing Tencent SSL certificate ID when ssl_create_mode is existing."
  default     = null
}

variable "ssl_certificate_pem" {
  type        = string
  description = "PEM certificate chain when ssl_create_mode is upload."
  default     = null
  sensitive   = true
}

variable "ssl_private_key_pem" {
  type        = string
  description = "PEM private key when ssl_create_mode is upload."
  default     = null
  sensitive   = true
}

variable "ssl_dv_auth_method" {
  type        = string
  description = "Free cert DV method: DNS (manual DNS record), DNS_AUTO (Tencent Cloud DNS), or FILE."
  default     = "DNS"
}

variable "ssl_contact_email" {
  type        = string
  description = "Contact email for free SSL certificate application."
  default     = ""
}

variable "ssl_contact_phone" {
  type        = string
  description = "Contact phone for free SSL certificate application."
  default     = ""
}

variable "ssl_auto_complete" {
  type        = bool
  description = "After DNS validation records are in place, run certificate issuance on apply."
  default     = true
}
