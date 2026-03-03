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