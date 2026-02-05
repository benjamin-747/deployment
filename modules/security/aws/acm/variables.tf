variable "domain_name" {
  type        = string
  description = "Primary domain name for the certificate"
}

variable "alternative_names" {
  type        = list(string)
  description = "Optional SANs"
  default     = []
}

variable "tags" {
  type        = map(string)
  default     = {}
}