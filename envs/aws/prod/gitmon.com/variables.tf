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

variable "redis_endpoint" {
  type      = string
  sensitive = true
}


variable "vpc_id" {
  type      = string
}


variable "vpc_cidr" {
  type      = string
}


variable "public_subnet_ids" {
  description = "IDs of all public subnets"
  type        = list(string)
}


variable "existing_alb_arn" {
  type    = string
  default = ""
}

variable "existing_https_listener_arn" {
  type    = string
  default = ""
}

variable "ec2_ami" {
  type = string
  default = ""
}

variable "ec2_instance_type" {
  type    = string
  default = "t3.micro"
}
