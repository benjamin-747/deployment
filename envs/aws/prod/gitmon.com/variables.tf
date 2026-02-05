variable "base_domain" {
  type = string
}

variable "region" {
  type = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}
variable "db_schema" {
  type      = string
}

variable "s3_key" {
  type      = string
  sensitive = true
}

variable "s3_secret_key" {
  type      = string
  sensitive = true
}

variable "s3_bucket" {
  type = string
}

variable "rails_master_key" {
  type      = string
  sensitive = true
}

variable "rails_env" {
  type = string
}

variable "ui_env" {
  type = string
}

variable "app_suffix" {
  type = string
}
