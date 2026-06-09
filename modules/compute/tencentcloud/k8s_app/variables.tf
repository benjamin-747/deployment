variable "name" {
  type        = string
  description = "Workload name (used for Deployment, Service and selector label)"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace"
  default     = "default"
}

variable "image" {
  type        = string
  description = "Container image (with tag)"
}

variable "container_port" {
  type        = number
  description = "Container listening port"
}

variable "replicas" {
  type        = number
  description = "Number of pod replicas"
  default     = 1
}

variable "cpu" {
  type        = string
  description = "CPU request/limit as a Kubernetes quantity (e.g. 500m). On TKE super nodes requests == limits."
  default     = "500m"
}

variable "memory" {
  type        = string
  description = "Memory request/limit as a Kubernetes quantity (e.g. 1024Mi)."
  default     = "1024Mi"
}

variable "environment" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Environment variables for the container"
  default     = []
}

variable "service_type" {
  type        = string
  description = "Kubernetes Service type: ClusterIP, NodePort or LoadBalancer"
  default     = "ClusterIP"
}

variable "enable_eip" {
  type        = bool
  description = "Assign a public EIP to each pod (TKE super node egress to the internet)."
  default     = false
}

variable "eip_bandwidth" {
  type        = number
  description = "Per-pod EIP outbound bandwidth cap in Mbps (InternetMaxBandwidthOut)."
  default     = 100
}

variable "eip_charge_type" {
  type        = string
  description = "EIP internet charge type, e.g. TRAFFIC_POSTPAID_BY_HOUR or BANDWIDTH_POSTPAID_BY_HOUR."
  default     = "TRAFFIC_POSTPAID_BY_HOUR"
}

variable "labels" {
  type        = map(string)
  description = "Extra labels merged onto pods and selectors"
  default     = {}
}
