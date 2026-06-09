variable "name" {
  type        = string
  description = "CLB instance name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the CLB"
}

# OPEN (public) CLBs do not require a subnet. Kept for interface parity.
variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs (unused for OPEN CLB; kept for interface parity)"
  default     = []
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs attached to the CLB"
  default     = []
}

variable "enable_https" {
  type        = bool
  description = "Create an HTTPS listener and attach forwarding rules to it. Set explicitly when certificate_id is only known after apply (e.g. free SSL workflow)."
  default     = false
}

variable "certificate_id" {
  type        = string
  description = "SSL certificate ID for the HTTPS listener. Required when enable_https is true."
  default     = null
}

variable "http_port" {
  type        = number
  description = "HTTP listener port"
  default     = 80
}

variable "https_port" {
  type        = number
  description = "HTTPS listener port"
  default     = 443
}

variable "target_groups" {
  type = map(object({
    domain            = string
    url               = optional(string, "/")
    health_check_path = optional(string, "/")
    port              = optional(number, 80)
  }))
  description = "Forwarding rules keyed by service name (domain + url -> backend)"
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to CLB resources"
  default     = {}
}
