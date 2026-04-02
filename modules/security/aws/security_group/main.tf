resource "aws_security_group" "ecs_sg" {
  name        = "ecs-service-sg"
  description = "default sg for alb to ecs access"
  vpc_id      = var.vpc_id
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


output "sg_id" {
  value = aws_security_group.ecs_sg.id
}
