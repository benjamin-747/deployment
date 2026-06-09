provider "aws" {
  region = var.region
}

module "qlean_ec2_key" {
  source = "../../../modules/compute/aws/ec2_ssh_key"
  name   = "qlean-ec2"
}

module "qlean_ec2_vm" {
  source = "../../../modules/compute/aws/ec2"

  name                 = "qlean-ec2-vm"
  ami                  = var.ec2_ami
  instance_type        = var.ec2_instance_type
  vpc_id               = var.vpc_id
  subnet_ids           = var.public_subnet_ids
  key_name             = module.qlean_ec2_key.key_name
  orion_ssh_public_key = module.qlean_ec2_key.public_key_openssh
  root_volume_size     = var.root_volume_size
}

resource "aws_eip" "qlean_ec2_vm" {
  domain = "vpc"
  tags = {
    Name = "qlean-ec2-vm"
  }
}

resource "aws_eip_association" "qlean_ec2_vm" {
  allocation_id = aws_eip.qlean_ec2_vm.id
  instance_id   = module.qlean_ec2_vm.instance_id
}

output "qlean_ec2_vm_instance_id" {
  value = module.qlean_ec2_vm.instance_id
}

output "qlean_ec2_vm_public_ip" {
  value = aws_eip.qlean_ec2_vm.public_ip
}

output "qlean_ec2_vm_root_volume_id" {
  value = module.qlean_ec2_vm.root_volume_id
}