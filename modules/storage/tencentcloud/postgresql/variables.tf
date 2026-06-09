variable "name" {
  type        = string
  description = "PostgreSQL instance name"
}

variable "region" {
  type        = string
  description = "Tencent Cloud region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the database instance"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the database instance. The first subnet (and its AZ) is used."
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs allowed to access the database"
  default     = []
}

variable "db_username" {
  type        = string
  description = "Database root account name"
  sensitive   = true
}

variable "db_password" {
  type        = string
  description = "Database root account password (8-64 chars, mixed case + digits/symbols)"
  sensitive   = true
}

variable "db_schema" {
  type        = string
  description = "Default database name (created by the application at startup)"
}

variable "db_major_version" {
  type        = string
  description = "PostgreSQL major version (10, 11, 12, 13, 14, 15, 16)"
  default     = "15"
}

variable "charge_type" {
  type        = string
  description = "Billing mode: POSTPAID_BY_HOUR or PREPAID"
  default     = "POSTPAID_BY_HOUR"
}

variable "charset" {
  type        = string
  description = "Root database charset (UTF8 or LATIN1)"
  default     = "UTF8"
}

variable "cpu" {
  type        = number
  description = "Number of CPU cores. 0 = let the API pick based on memory. Must match a valid spec from tencentcloud_postgresql_specinfos."
  default     = 0
}

variable "memory" {
  type        = number
  description = "Memory size in GB"
  default     = 2
}

variable "storage" {
  type        = number
  description = "Storage size in GB (multiple of 10)"
  default     = 20
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the database instance"
  default     = {}
}
