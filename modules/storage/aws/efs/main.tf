
resource "aws_efs_file_system" "this" {
  creation_token = var.name
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted = true
  tags = {
    Name = var.name
  }
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

resource "aws_security_group" "efs" {
  name        = "${var.name}-sg"
  description = "Allow NFS traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_mount_target" "this" {
  for_each = { for i, id in var.subnet_ids : i => id }

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

output "file_system_id" {
  value = aws_efs_file_system.this.id
}

output "security_group_id" {
  value = aws_security_group.efs.id
}