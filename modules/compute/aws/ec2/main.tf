
# modules/ec2/main.tf
resource "aws_instance" "this" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = element(var.subnet_ids, 0)
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated.key_name



  user_data = <<-EOF
              #!/bin/bash
              if [ -f /etc/debian_version ]; then
                apt-get update -y
                apt-get install -y amazon-efs-utils
              else
                yum install -y amazon-efs-utils
              fi

              # 等待 EFS 可用
              mkdir -p ${var.mount_point}
              for i in {1..10}; do
                mount -t efs ${var.efs_id}:/ ${var.mount_point} && break
                sleep 10
              done

              chown -R ec2-user:ec2-user ${var.mount_point} || chown -R ubuntu:ubuntu ${var.mount_point}
              chmod 777 ${var.mount_point}
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

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.efs_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
