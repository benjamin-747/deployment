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
  description = "CPU request/limit as a Kubernetes quantity (e.g. 500m). Used for both requests and limits unless requests_cpu/limits_cpu are set."
  default     = "500m"
}

variable "memory" {
  type        = string
  description = "Memory request/limit as a Kubernetes quantity (e.g. 1024Mi)."
  default     = "1024Mi"
}

# Optional independent requests/limits. Empty = fall back to cpu/memory above
# (preserving requests == limits). On clusters that allow differing
# requests/limits (e.g. k3s), set these to overcommit safely.
variable "requests_cpu" {
  type        = string
  description = "CPU request override. Empty falls back to var.cpu."
  default     = ""
}

variable "requests_memory" {
  type        = string
  description = "Memory request override. Empty falls back to var.memory."
  default     = ""
}

variable "limits_cpu" {
  type        = string
  description = "CPU limit override. Empty falls back to var.cpu."
  default     = ""
}

variable "limits_memory" {
  type        = string
  description = "Memory limit override. Empty falls back to var.memory."
  default     = ""
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

variable "labels" {
  type        = map(string)
  description = "Extra labels merged onto pods and selectors"
  default     = {}
}
