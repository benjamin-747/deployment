variable "name" {
  type        = string
  description = "EKSCI instance name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID (one per instance)"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs"
}

variable "image" {
  type        = string
  description = "Container image"
}

variable "cpu" {
  type        = number
  description = "CPU cores for the instance and container (see EKSCI spec table)"
}

variable "memory" {
  type        = number
  description = "Memory in GiB for the instance and container"
}

variable "env_vars" {
  type        = map(string)
  description = "Container environment variables"
  default     = {}
}

variable "restart_policy" {
  type        = string
  description = "Always, Never, or OnFailure"
  default     = "Always"
}

variable "auto_create_eip" {
  type        = bool
  description = "Create a public EIP for internet egress (image pull, outbound APIs)"
  default     = true
}

variable "eip_bandwidth" {
  type        = number
  description = "EIP outbound bandwidth cap in Mbps when auto_create_eip is true"
  default     = 100
}

variable "eip_delete_policy" {
  type        = bool
  description = "Release the auto-created EIP when the instance is deleted"
  default     = true
}
