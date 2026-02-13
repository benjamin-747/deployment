variable "name" {
  type        = string
  description = "Cloud SQL instance name"
}

variable "database_version" {
  type        = string
  description = "Cloud SQL database version (e.g. POSTGRES_17, MYSQL_8_0)"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "tier" {
  type        = string
  description = "Instance tier"
}

variable "edition" {
  type        = string
  default     = "ENTERPRISE"
  description = "Cloud SQL edition (e.g. ENTERPRISE or ENTERPRISE_PLUS)"
}

variable "disk_size" {
  type        = number
  default     = 20
  description = "Disk size in GB"
}

variable "disk_type" {
  type        = string
  default     = "PD_SSD"
  description = "Disk type"
}

variable "availability_type" {
  type        = string
  default     = "ZONAL"
  description = "Availability type (ZONAL or REGIONAL)"
}

variable "private_network" {
  type        = string
  description = "VPC self link"
}



variable "enable_public_ip" {
  type        = bool
  default     = false
  description = "Enable public IPv4"
}

variable "db_name" {
  type        = string
  description = "Default database name"
}

variable "db_username" {
  type        = string
  description = "Database username"
}

variable "db_password" {
  type        = string
  description = "Database password"
  sensitive   = true
}

variable "backup_enabled" {
  type        = bool
  default     = true
  description = "Enable automated backups"
}

variable "deletion_protection" {
  type        = bool
  default     = false
  description = "Enable deletion protection"
}

