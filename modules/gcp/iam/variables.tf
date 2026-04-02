variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "app_name" {
  type        = string
  description = "The name of the application, used as a prefix for all resources"
}

variable "service_accounts" {
  type = map(object({
    display_name = optional(string)
    description  = optional(string)
    roles        = optional(list(string), [])
    wi_bindings = optional(list(object({
      namespace                = string
      k8s_service_account_name = string
    })), [])
  }))
  description = "Service accounts to create and their IAM roles / Workload Identity bindings"
  default     = {}
}

