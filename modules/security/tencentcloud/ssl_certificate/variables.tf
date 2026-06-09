variable "domain_name" {
  type        = string
  description = "Certificate domain. Free certs support a single FQDN only; use upload mode for wildcards (e.g. *.example.com)."
}

variable "create_mode" {
  type        = string
  description = "How to obtain the certificate: free (DV), upload (bring your own PEM), existing (use certificate_id), or disabled."
  default     = "free"

  validation {
    condition     = contains(["free", "upload", "existing", "disabled"], var.create_mode)
    error_message = "create_mode must be one of: free, upload, existing, disabled."
  }

  validation {
    condition     = var.create_mode != "free" || !startswith(var.domain_name, "*.")
    error_message = "Tencent free certificates do not support wildcards. Use create_mode \"upload\" for *.domain certs, or set domain_name to a single hostname (e.g. app.example.com)."
  }

  validation {
    condition     = var.create_mode != "existing" || (var.certificate_id != null && var.certificate_id != "")
    error_message = "certificate_id is required when create_mode is existing."
  }

  validation {
    condition     = var.create_mode != "upload" || (var.certificate_pem != null && var.private_key_pem != null && var.certificate_pem != "" && var.private_key_pem != "")
    error_message = "certificate_pem and private_key_pem are required when create_mode is upload."
  }
}

variable "certificate_id" {
  type        = string
  description = "Existing SSL certificate ID when create_mode is existing."
  default     = null
}

variable "certificate_pem" {
  type        = string
  description = "PEM-encoded certificate chain when create_mode is upload."
  default     = null
  sensitive   = true
}

variable "private_key_pem" {
  type        = string
  description = "PEM-encoded private key when create_mode is upload."
  default     = null
  sensitive   = true
}

variable "certificate_name" {
  type        = string
  description = "Display name for uploaded certificates."
  default     = null
}

variable "dv_auth_method" {
  type        = string
  description = "DV validation method for free certificates: DNS_AUTO (domain on Tencent Cloud DNS), DNS (manual DNS record), or FILE."
  default     = "DNS"

  validation {
    condition     = contains(["DNS_AUTO", "DNS", "FILE"], var.dv_auth_method)
    error_message = "dv_auth_method must be DNS_AUTO, DNS, or FILE."
  }
}

variable "contact_email" {
  type        = string
  description = "Contact email for free certificate application."
  default     = ""
}

variable "contact_phone" {
  type        = string
  description = "Contact phone for free certificate application."
  default     = ""
}

variable "package_type" {
  type        = string
  description = "Free certificate package type. Use 83 for TrustAsia C1 DV Free."
  default     = "83"
}

variable "auto_complete" {
  type        = bool
  description = "For free certificates, run domain verification and issuance after apply. Requires DNS records to be in place; re-run apply if the first attempt fails."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the certificate resource"
  default     = {}
}
