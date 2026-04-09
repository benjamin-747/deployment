variable "name" {}
variable "ami" {}
variable "instance_type" {}

# Key pair comes from modules/compute/aws/ec2_ssh_key (or equivalent) so EC2 destroy does not rotate keys.
variable "key_name" {
  type        = string
  description = "AWS EC2 key pair name"
}

variable "orion_ssh_public_key" {
  type        = string
  description = "OpenSSH public key for the orion user in cloud-init"
}

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

variable "root_volume_size" {
  type        = number
  default     = null
  description = "Root EBS volume size in GiB. If null, the AMI default is used."
}