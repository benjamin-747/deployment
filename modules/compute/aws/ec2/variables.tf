variable "name" {}
variable "ami" {}
variable "instance_type" {}

# Optional EFS parameters. If omitted/empty, the instance will not mount EFS
# and the EC2 security group will not open NFS (2049).
variable "efs_id" {
  type    = string
  default = null
}

variable "mount_point" {
  type    = string
  default = null
}

variable "efs_sg_id" {
  type    = string
  default = null
}

variable "vpc_id" {}
variable "subnet_ids" {}