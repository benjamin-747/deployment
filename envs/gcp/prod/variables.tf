# NOTE: cleaned up variables, removed k8s/ingress legacy blocks

variable "project_id" {
  type = string
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

variable "name_prefix" {
  type    = string
  default = "mega-prod"
}

variable "base_domain" {
  type    = string
  default = ""
}

variable "enable_build_env" {
  type        = bool
  description = "(deprecated) Was used for GKE build env. Default to false after migration to Cloud Run."
  default     = false
}

variable "enable_gcs" {
  type    = bool
  default = true
}

variable "enable_cloud_sql" {
  type    = bool
  default = true
}

variable "enable_redis" {
  type    = bool
  default = true
}

variable "enable_filestore" {
  type    = bool
  default = true
}

variable "enable_apps" {
  type    = bool
  default = true
}

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
  type        = list(string)
  default     = []
  description = "List of notification channel IDs for alerts"
}

variable "log_sink_name" {
  type    = string
  default = ""
}

variable "log_sink_destination" {
  type    = string
  default = ""
}

variable "network_name" {
  type    = string
  default = "mega-prod-net"
}

variable "subnet_name" {
  type    = string
  default = "mega-prod-subnet"
}

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

# Private networking for Cloud SQL / Redis (Cloud Run -> VPC Connector)
variable "enable_private_networking" {
  type    = bool
  default = true
}

variable "vpc_connector_name" {
  type    = string
  default = ""
}

variable "vpc_connector_cidr" {
  type    = string
  default = null
}

variable "cloud_run_vpc_egress" {
  type    = string
  default = "private-ranges-only"
}

variable "artifact_registry_location" {
  type    = string
  default = "us-central1"
}

variable "artifact_registry_repo" {
  type        = string
  description = "Artifact Registry repository name"
  default     = "mega-prod"
}

variable "gcs_bucket" {
  type        = string
  description = "GCS bucket name"
  default     = ""
}

variable "gcs_force_destroy" {
  type        = bool
  description = "Allow force deletion of bucket objects"
  default     = false
}

variable "gcs_uniform_bucket_level_access" {
  type        = bool
  description = "Enable uniform bucket-level access"
  default     = true
}

variable "cloud_sql_instance_name" {
  type        = string
  description = "Cloud SQL instance name"
  default     = ""
}

variable "cloud_sql_database_version" {
  type        = string
  description = "Cloud SQL database version"
  default     = "POSTGRES_17"
}

variable "cloud_sql_tier" {
  type        = string
  description = "Cloud SQL instance tier"
  default     = "db-g1-small"
}

variable "cloud_sql_disk_size" {
  type        = number
  description = "Cloud SQL disk size in GB"
  default     = 100
}

variable "cloud_sql_disk_type" {
  type        = string
  description = "Cloud SQL disk type"
  default     = "PD_SSD"
}

variable "cloud_sql_availability_type" {
  type        = string
  description = "Cloud SQL availability type"
  default     = "REGIONAL"
}

variable "cloud_sql_private_ip_prefix_length" {
  type        = number
  description = "Prefix length for private services range"
  default     = 16
}

variable "cloud_sql_enable_private_service_connection" {
  type    = bool
  default = true
}

variable "cloud_sql_enable_public_ip" {
  type    = bool
  default = false
}

variable "cloud_sql_db_name" {
  type    = string
  default = ""
}

variable "cloud_sql_backup_enabled" {
  type    = bool
  default = true
}

variable "cloud_sql_deletion_protection" {
  type    = bool
  default = true
}

variable "redis_instance_name" {
  type        = string
  description = "Memorystore instance name"
  default     = ""
}

variable "redis_tier" {
  type    = string
  default = "STANDARD_HA"
}

variable "redis_memory_size_gb" {
  type    = number
  default = 4
}

variable "redis_transit_encryption_mode" {
  type    = string
  default = "DISABLED"
}

variable "filestore_instance_name" {
  type    = string
  default = ""
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

# Cloud Run application variables
variable "app_service_name" {
  type        = string
  description = "Cloud Run service name"
  default     = ""
}

variable "app_image" {
  type        = string
  description = "Container image"
  default     = ""
}

variable "app_env" {
  type        = map(string)
  description = "Environment variables for Cloud Run"
  default     = {}
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

variable "storage_bucket" {
  type    = string
  default = ""
}

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

variable "db_schema" {
  type    = string
  default = ""
}

variable "rails_master_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "rails_env" {
  type    = string
  default = ""
}

variable "ui_env" {
  type    = string
  default = ""
}

# Cloud Run UI variables
variable "ui_service_name" {
  type        = string
  description = "Cloud Run service name for UI"
  default     = ""
}

variable "ui_image" {
  type        = string
  description = "Container image for UI"
  default     = ""
}

variable "ui_env_vars" {
  type        = map(string)
  description = "Environment variables for UI Cloud Run"
  default     = {}
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

variable "app_suffix" {
  type    = string
  default = ""
}

variable "iam_service_accounts" {
  type = map(object({
    display_name = optional(string)
    description  = optional(string)
    roles        = optional(list(string), [])
    wi_bindings  = optional(list(object({
      namespace                 = string
      k8s_service_account_name  = string
    })), [])
  }))
  default = {}
}
