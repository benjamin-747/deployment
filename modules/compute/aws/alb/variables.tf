variable "name" {
  description = "ALB name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for target group"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for ALB"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups for ALB"
  type        = list(string)
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
}

variable "internal" {
  description = "Whether ALB is internal"
  type        = bool
  default     = false
}

variable "target_groups" {
  description = "Map of target groups to create"
  type = map(object({
    name              = string
    port              = number
    health_check_path = string
  }))
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
