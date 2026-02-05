variable "name" {
  type        = string
  default     = "main-vpc"
  description = "VPC name prefix"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR block"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDRs for public subnets"
}
