# --- Project & App Identity ---
variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "app_name" {
  type        = string
  description = "The name of the application, used as a prefix for all resources"
  default     = "mega"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type        = string
  description = "GCP zone for zonal resources (e.g. Filestore)."
  default     = ""
}

variable "base_domain" {
  type        = string
  description = "The FQDN for the application (e.g., buck2hub.com)"
  default     = "buck2hub.com"
}




variable "enable_lb" {
  type        = bool
  description = "Whether to enable Global HTTPS Load Balancer"
  default     = true
}

# --- Network Configuration ---
variable "subnet_cidr" {
  type    = string
  default = "10.40.0.0/16"
}

variable "pods_secondary_range" {
  type    = string
  default = "10.41.0.0/16"
}

variable "services_secondary_range" {
  type    = string
  default = "10.42.0.0/16"
}

variable "enable_private_networking" {
  type    = bool
  default = true
}

variable "vpc_connector_cidr" {
  type    = string
  default = "10.8.0.0/28"
}



# --- Storage (GCS) ---
variable "gcs_bucket" {
  type        = string
  description = "Optional GCS bucket override. If empty, Terraform will derive a default name from app_name."
  default     = ""
}

variable "gcs_force_destroy" {
  type    = bool
  default = false
}

variable "gcs_uniform_bucket_level_access" {
  type    = bool
  default = true
}

# --- Database (Cloud SQL) ---

variable "cloud_sql_enable_public_ip" {
  type    = bool
  default = false
}

variable "cloud_sql_pg_name" {
  type = string
}

variable "cloud_sql_mysql_name" {
  type = string
}

# --- Redis (Memorystore) ---
variable "redis_instance_name" {
  type        = string
  description = "Optional Redis instance name override."
  default     = ""
}



variable "redis_memory_size_gb" {
  type    = number
  default = 1
}

variable "redis_transit_encryption_mode" {
  type    = string
  default = "DISABLED"
}

# --- Filestore ---
variable "filestore_instance_name" {
  type        = string
  description = "Optional Filestore instance name override."
  default     = ""
}

variable "filestore_tier" {
  type    = string
  default = "STANDARD"
}

variable "filestore_capacity_gb" {
  type    = number
  default = 1024
}

variable "filestore_file_share_name" {
  type    = string
  default = "share1"
}

variable "filestore_reserved_ip_range" {
  type    = string
  default = null
}

# --- Cloud Run: Backend App ---
variable "app_image" {
  type    = string
  default = ""
}

variable "mono_env" {
  type    = map(string)
  default = {}
}

variable "app_cpu" {
  type    = string
  default = "1"
}

variable "app_memory" {
  type    = string
  default = "512Mi"
}

variable "app_min_instances" {
  type    = number
  default = 0
}

variable "app_max_instances" {
  type    = number
  default = 10
}

variable "app_allow_unauth" {
  type    = bool
  default = true
}

# --- Cloud Run: UI ---
variable "ui_image" {
  type    = string
  default = ""
}

variable "ui_env_vars" {
  type    = map(string)
  default = {}
}

variable "ui_cpu" {
  type    = string
  default = "1"
}

variable "ui_memory" {
  type    = string
  default = "512Mi"
}

variable "ui_min_instances" {
  type    = number
  default = 0
}

variable "ui_max_instances" {
  type    = number
  default = 10
}

variable "ui_allow_unauth" {
  type    = bool
  default = true
}

# --- Cloud Run: Orion Server ---
variable "orion_image" {
  type    = string
  default = ""
}

variable "orion_env_vars" {
  type    = map(string)
  default = {}
}

# --- Cloud Run: Campsite ---
variable "campsite_image" {
  type    = string
  default = ""
}

variable "campsite_env_vars" {
  type    = map(string)
  default = {}
}

# --- IAM & Service Accounts ---
variable "app_suffix" {
  type    = string
  default = ""
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
  description = "Service accounts to create and their IAM roles"
}

# --- Monitoring & Logging ---
variable "enable_logging" {
  type    = bool
  default = true
}

variable "enable_monitoring" {
  type    = bool
  default = true
}

variable "enable_alerts" {
  type    = bool
  default = true
}

variable "alert_notification_channels" {
  type    = list(string)
  default = []
}

variable "log_sink_name" {
  type    = string
  default = ""
}

variable "log_sink_destination" {
  type    = string
  default = ""
}

# --- Load Balancer Routing ---
variable "lb_api_path_prefixes" {
  type        = list(string)
  description = "URL path prefixes to be routed to the backend service"
  default     = ["/api/v1", "/info/lfs"]
}

# --- Secrets (Sensitive Variables) ---
variable "db_username" {
  type      = string
  sensitive = true
  default   = ""
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "rails_master_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "storage_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "storage_secret_key" {
  type      = string
  sensitive = true
  default   = ""
}
