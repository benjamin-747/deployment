variable "name" {}
variable "vpc_id" {}
variable "vpc_cidr" {}
variable "subnet_ids" {
  type = list(string)
}

