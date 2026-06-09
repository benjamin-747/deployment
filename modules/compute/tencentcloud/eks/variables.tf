variable "name" {
  type        = string
  description = "Cluster name / resource prefix"
}

variable "region" {
  type        = string
  description = "Tencent Cloud region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the cluster"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs used as ENI subnets and serverless node subnets"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs attached to the serverless node pool"
  default     = []
}

variable "k8s_version" {
  type        = string
  description = "Kubernetes version. Empty string lets TKE pick a supported default."
  default     = ""
}

variable "serverless_subnet_ids" {
  type        = list(string)
  description = "Subnets used to place serverless (super) nodes. One super node per subnet. Empty = use all subnet_ids."
  default     = []
}

variable "service_cidr" {
  type        = string
  description = "Service CIDR for VPC-CNI. cluster_max_service_num is derived from it."
  default     = "172.16.0.0/20"
}

variable "cluster_max_pod_num" {
  type        = number
  description = "Max pods per node"
  default     = 64
}

variable "cluster_public_access" {
  type        = bool
  description = "Expose the Kubernetes API server on a public endpoint (required for managing workloads from outside the VPC). Access is controlled by the first security group in security_group_ids (must allow inbound 443)."
  default     = true
}

variable "services" {
  type = map(object({
    image  = string
    port   = number
    host   = optional(string, "")
    cpu    = string
    memory = string
    environment = optional(list(object({
      name  = string
      value = string
    })), [])
  }))
  description = "Per-service workload definitions (consumed by the Kubernetes manifest layer)."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the cluster"
  default     = {}
}
