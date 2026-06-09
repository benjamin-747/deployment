variable "base_domain" {
  type = string
}

# Tags applied (via provider default_tags) to every resource THIS env creates.
# Shared resources referenced by ARN (existing_alb_arn / existing_https_listener_arn)
# are not managed here and therefore are not tagged.
variable "default_tags" {
  type    = map(string)
  default = {}
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

variable "app_suffix" {
  type = string
}

# ---------------------------
# internship-portal app env
# ---------------------------
variable "atomgit_client_id" {
  type = string
}

variable "atomgit_client_secret" {
  type      = string
  sensitive = true
}

variable "better_auth_secret" {
  type      = string
  sensitive = true
}

variable "github_client_id" {
  type = string
}

variable "github_client_secret" {
  type      = string
  sensitive = true
}

variable "s3_endpoint" {
  type        = string
  description = "S3 (or S3-compatible) endpoint URL for the portal app"
}

variable "opensource_integration_token" {
  type      = string
  sensitive = true
}

variable "email_enabled" {
  type    = string
  default = "true"
}

variable "zepto_api_key" {
  type      = string
  sensitive = true
}

variable "email_default_from" {
  type        = string
  description = "Default From address for portal outbound email"
}

variable "s3_force_path_style" {
  type    = string
  default = "true"
}

# ---------------------------
# internship-bot app env
# ---------------------------
variable "bot_private_key" {
  type      = string
  sensitive = true
}

variable "bot_webhook_secret" {
  type      = string
  sensitive = true
}

variable "bot_github_client_id" {
  type = string
}

variable "bot_github_client_secret" {
  type      = string
  sensitive = true
}

variable "bot_atomgit_token" {
  type      = string
  sensitive = true
}

variable "bot_app_id" {
  type = string
}

# ---------------------------
# internship-score-api app env
# ---------------------------
variable "zepto_ak" {
  type      = string
  sensitive = true
}

variable "zepto_sk" {
  type      = string
  sensitive = true
}

variable "send_email" {
  type    = string
  default = "false"
}


variable "vpc_id" {
  type = string
}

# Existing security group id (shared, e.g. gitmono's "ecs-service-sg") reused for
# ALB <-> ECS access. Passed in instead of creating a new SG to avoid name collisions
# within the shared VPC.
variable "ecs_sg" {
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

# ECS Fargate: per-service cpu (AWS units) and memory (MiB). Merge with defaults in main.tf locals.
variable "ecs_fargate_tasks" {
  type = map(object({
    cpu    = string
    memory = string
  }))
  default     = {}
  description = "Optional overrides. Keys: internship-portal, internship-docs, internship-bot, internship-score-api"
}
