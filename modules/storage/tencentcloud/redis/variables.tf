variable "name" {
  type        = string
  description = "Redis instance name"
}

variable "region" {
  type        = string
  description = "Tencent Cloud region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the Redis instance"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the Redis instance. The first subnet (and its AZ) is used."
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs allowed to access Redis"
  default     = []
}

variable "password" {
  type        = string
  description = "Redis auth password (8-16 chars, mixed case + digits)"
  sensitive   = true
}

variable "type_id" {
  type        = number
  description = "Instance type / product version. 19 = Valkey 8.0 standard architecture, 20 = Valkey 8.0 cluster, 15 = Redis 6.2 standard."
  default     = 19
}

variable "replicas_num" {
  type        = number
  description = "Number of replicas (single-AZ when replica_zone_ids is unset)"
  default     = 1
}

variable "memory_size" {
  type        = number
  description = "Memory size in MB"
  default     = 1024
}

variable "port" {
  type        = number
  description = "Redis access port"
  default     = 6379
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the Redis instance"
  default     = {}
}
