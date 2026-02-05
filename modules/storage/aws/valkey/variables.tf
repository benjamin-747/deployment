variable "name" {
  type = string
}

variable "engine" {
  type    = string
  default = "valkey"
}

variable "engine_version" {
  type    = string
  default = "8.1"
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "description" {
  type    = string
  default = "valkey serverless cache"
}

variable "tags" {
  type    = map(string)
  default = {}
}