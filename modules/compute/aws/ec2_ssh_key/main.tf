locals {
  key_name = "${var.name}-key"
  pem_path = abspath("${path.module}/${local.key_name}.pem")
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = var.rsa_bits
}

resource "aws_key_pair" "this" {
  key_name   = local.key_name
  public_key = tls_private_key.this.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.this.private_key_pem
  filename        = local.pem_path
  file_permission = "0600"
}
