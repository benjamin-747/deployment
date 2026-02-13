variable "name" {
  type        = string
  description = "Memorystore instance name"
}

variable "project_id" {
  type = string
}

variable "region" {
  type        = string
  description = "GCP region"
}


variable "memory_size_gb" {
  type        = number
  default     = 1
  description = "Memory size in GB"
}

variable "network" {
  type        = string
  description = "VPC self link"
}

variable "transit_encryption_mode" {
  type        = string
  default     = "DISABLED"
  description = "Transit encryption mode"
}

