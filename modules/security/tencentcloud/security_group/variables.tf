variable "name" {
  type        = string
  description = "Security group name"
}

# Tencent Cloud security groups are region-scoped and not bound to a VPC.
# Kept for interface parity with the AWS module; currently unused.
variable "vpc_id" {
  type        = string
  description = "VPC ID (unused; TC security groups are region-scoped)"
  default     = ""
}

variable "ingress_rules" {
  type = list(object({
    action      = optional(string, "ACCEPT")
    protocol    = string
    port        = string
    cidr_block  = string
    description = optional(string, "")
  }))
  description = "Inbound rules (ordered; first rule has highest priority)"
  default = [
    {
      action      = "ACCEPT"
      protocol    = "TCP"
      port        = "80"
      cidr_block  = "0.0.0.0/0"
      description = "HTTP"
    },
    {
      action      = "ACCEPT"
      protocol    = "TCP"
      port        = "443"
      cidr_block  = "0.0.0.0/0"
      description = "HTTPS"
    },
  ]
}

variable "egress_rules" {
  type = list(object({
    action      = optional(string, "ACCEPT")
    protocol    = string
    port        = string
    cidr_block  = string
    description = optional(string, "")
  }))
  description = "Outbound rules (ordered; first rule has highest priority)"
  default = [
    {
      action      = "ACCEPT"
      protocol    = "ALL"
      port        = "ALL"
      cidr_block  = "0.0.0.0/0"
      description = "Allow all egress"
    },
  ]
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the security group"
  default     = {}
}
