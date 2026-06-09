variable "name" {
  type        = string
  description = "VPC name prefix"
}

variable "region" {
  type        = string
  description = "Tencent Cloud region (e.g. ap-guangzhou)"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDR blocks, one per availability zone"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to VPC and subnet resources"
  default     = {}
}
