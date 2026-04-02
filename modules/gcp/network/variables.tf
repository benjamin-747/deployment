variable "app_name" {
  type = string
}

variable "region" {
  type = string
}

variable "network_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = []
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = []
}

variable "enable_private_google_access" {
  type    = bool
  default = true
}

variable "create_nat" {
  type    = bool
  default = true
}

variable "allow_ssh" {
  type    = bool
  default = false
}
