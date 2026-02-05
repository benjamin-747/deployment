variable "region" {
  type        = string
  description = "AWS region"
}
variable "cluster_name" {}
variable "task_family" {}
variable "environment" {}
variable "mount_points" {
  type    = list(any)
  default = []
}
variable "efs_volume" {
  type    = map(string)
  default = null
}
variable "container_name" {}
variable "container_image" {}
variable "container_port" {}
variable "service_name" {}
variable "desired_count" { default = 1 }
variable "cpu" {}
variable "memory" {}
variable "subnet_ids" {
  description = "List of subnet IDs for ECS service"
  type        = list(string)
}
variable "security_group_ids" { type = list(string) }

variable "load_balancers" {
  description = "List of load balancers for this service. Each item should have target_group_arn, container_name, container_port, host_header"
  type = list(object({
    target_group_arn = string
    container_name   = string
    container_port   = number
    host_headers     = list(string)
    priority         = number
  }))
  default = []
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener"
  type        = string
  default     = null
}
