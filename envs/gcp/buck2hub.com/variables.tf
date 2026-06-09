# --- Core (GCP project & app) ---
variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "app_name" {
  type        = string
  description = "Prefix for resource names (Cloud Run services, buckets, etc.)"
  default     = "mega"
}

variable "region" {
  type        = string
  description = "Default GCP region for regional resources"
}

variable "zone" {
  type        = string
  description = "GCP zone for zonal resources (e.g. Compute Engine VMs)"
}

variable "base_domain" {
  type        = string
  description = "Public app domain (no scheme), e.g. buck2hub.com"
  default     = "buck2hub.com"
}

# --- Network ---
variable "vpc_subnet_cidr" {
  type        = string
  description = "Primary subnet CIDR for the app VPC"
  default     = "10.40.0.0/16"
}

variable "vpc_serverless_connector_cidr" {
  type        = string
  description = "Reserved /28 (or wider) for Serverless VPC Access connector used by Cloud Run"
  default     = "10.8.0.0/28"
}

# --- Load balancer ---
variable "load_balancer_enabled" {
  type        = bool
  description = "Provision global HTTPS load balancer in front of Cloud Run"
  default     = true
}

# --- GCS ---
variable "gcs_force_destroy" {
  type        = bool
  description = "Allow Terraform to delete bucket even if it contains objects"
  default     = false
}

variable "gcs_uniform_bucket_level_access" {
  type    = bool
  default = true
}

# --- Cloud SQL ---
variable "cloud_sql_enable_public_ip" {
  type        = bool
  description = "Expose a public IPv4 on Cloud SQL in addition to private IP"
  default     = false
}

variable "cloud_sql_pg_name" {
  type        = string
  description = "Logical database name on the PostgreSQL instance"
}

variable "cloud_sql_pg_tier" {
  type        = string
  description = "Machine tier for the PostgreSQL instance"
  default     = "db-f1-micro"
}

variable "cloud_sql_pg_disk_size_gb" {
  type        = number
  description = "Data disk size (GB) for PostgreSQL"
  default     = 10
}

variable "cloud_sql_mysql_name" {
  type        = string
  description = "Logical database name on the MySQL instance"
}

variable "cloud_sql_username" {
  type        = string
  description = "DB user for both PostgreSQL and MySQL instances"
  sensitive   = true
  default     = ""
}

variable "cloud_sql_password" {
  type        = string
  description = "Password for cloud_sql_username"
  sensitive   = true
  default     = ""
}

# --- Memorystore (Redis) ---
variable "redis_memory_size_gb" {
  type    = number
  default = 1
}

variable "redis_transit_encryption_mode" {
  type    = string
  default = "DISABLED"
}

# --- Cloud Run ---
variable "cloud_run_resources" {
  description = "Per-service CPU and memory for Cloud Run"
  type = list(object({
    service = string
    cpu     = string
    memory  = string
  }))
  default = [
    { service = "mono", cpu = "1", memory = "512Mi" },
    { service = "ui", cpu = "1", memory = "512Mi" },
    { service = "notesync", cpu = "1", memory = "256Mi" },
    { service = "orion", cpu = "1", memory = "256Mi" },
    { service = "campsite", cpu = "1", memory = "1024Mi" },
  ]
}

variable "cloud_run_ui_env" {
  type        = map(string)
  description = "Extra environment variables for the UI Cloud Run service"
  default     = {}
}

# --- Orion client VM ---
variable "orion_vm_machine_type" {
  type        = string
  description = "Machine type for the Orion client VM"
  default     = "e2-micro"
}

variable "orion_vm_boot_disk_size_gb" {
  type        = number
  description = "Boot disk size (GB) for the Orion client VM"
  default     = 10
}

variable "orion_vm_ssh_allowed_cidrs" {
  type        = list(string)
  description = "Source CIDRs allowed to SSH (TCP/22) to the Orion VM (network tag orion-ssh)"
  default     = ["0.0.0.0/0"]
}

# --- Local artifact ---
variable "orion_vm_private_key_file_path" {
  type        = string
  description = "Path to write the Orion VM SSH private key (OpenSSH). If relative, it will be written under this env directory (path.module)."
  default     = "orion_vm_ed25519"
}

# --- IAM ---
variable "iam_app_name_override" {
  type        = string
  description = "If non-empty, used as IAM module app_name for service account IDs instead of app_name"
  default     = ""
}

variable "iam_service_accounts" {
  type = map(object({
    display_name = optional(string)
    description  = optional(string)
    roles        = optional(list(string), [])
    wi_bindings = optional(list(object({
      namespace                = string
      k8s_service_account_name = string
    })), [])
  }))
  default     = {}
  description = "Service accounts to create and their project IAM roles"
}

# --- Monitoring ---
variable "monitoring_alert_notification_channel_ids" {
  type        = list(string)
  description = "Cloud Monitoring notification channel resource names for alert policies"
  default     = []
}

variable "monitoring_log_sink_name" {
  type        = string
  description = "Optional log sink name; default is `<app_name>-log-sink` in the monitoring module"
  default     = ""
}

variable "monitoring_log_sink_destination" {
  type        = string
  description = "If set, create a log export sink (e.g. bigquery.googleapis.com/projects/.../datasets/...)"
  default     = ""
}

# --- Application secrets ---
variable "rails_master_key" {
  type      = string
  sensitive = true
  default   = ""
}
