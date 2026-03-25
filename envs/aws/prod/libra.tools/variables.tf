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


variable "github_client_id" {
  type = string
}

variable "github_client_secret" {
  type = string
}

variable "jwt_secret" {
  type = string
}

variable "internal_verify_token" {
  type        = string
  sensitive   = true
  description = "Shared secret for internal service verification (distribution)"
}

variable "s3_key" {
  type = string
}
variable "s3_secret_key" {
  type = string
}
variable "s3_bucket" {
  type = string
}

variable "vpc_id" {
  type = string
}


variable "vpc_cidr" {
  type = string
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

variable "alb_sg" {
  type = string
}

variable "ecs_sg" {
  type = string
}