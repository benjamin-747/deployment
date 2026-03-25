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
  type = string
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

variable "ec2_ami" {
  type    = string
  default = ""
}

variable "ec2_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ecs_fargate_tasks" {
  type = map(object({
    cpu    = string
    memory = string
  }))
  default     = {}
  description = "Optional overrides. Keys: mono_engine, mega_ui, mega_web_sync, orion_server, campsite_api"
}
