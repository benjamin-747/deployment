
# modules/ec2/main.tf
resource "aws_instance" "this" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = element(var.subnet_ids, 0)
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  user_data_replace_on_change = true



  user_data = <<-EOF
#cloud-config
users:
  - default
  - name: orion
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${var.orion_ssh_public_key}

runcmd:
  - |
    if [ -n "${var.efs_id != null ? var.efs_id : ""}" ]; then
      mkdir -p "${var.mount_point != null ? var.mount_point : "/mnt/efs"}"

      if [ -f /etc/debian_version ]; then
        apt-get update -y || true
        apt-get install -y amazon-efs-utils || true
      else
        yum install -y amazon-efs-utils || true
      fi

      for i in {1..10}; do
        mount -t efs "${var.efs_id != null ? var.efs_id : ""}:/" "${var.mount_point != null ? var.mount_point : "/mnt/efs"}" && break || true
        sleep 10
      done

      chown -R orion:orion "${var.mount_point != null ? var.mount_point : "/mnt/efs"}" || true
      chmod 777 "${var.mount_point != null ? var.mount_point : "/mnt/efs"}" || true
    fi
EOF

  tags = {
    Name = var.name
  }
}

resource "aws_security_group" "ec2" {
  name   = "${var.name}-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = (var.efs_sg_id != null && var.efs_sg_id != "") ? [1] : []
    content {
      from_port       = 2049
      to_port         = 2049
      protocol        = "tcp"
      security_groups = [var.efs_sg_id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
