variable "region" {
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

variable "ec2_ami" {
  type    = string
  default = ""
}

variable "ec2_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "root_volume_size" {
  type    = number
  default = 20
}