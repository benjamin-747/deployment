resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.engine}-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = { Name = "${var.engine}-subnet-group" }
}

resource "aws_db_instance" "db" {
  identifier             = var.identifier
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  storage_type           = var.storage_type
  username               = var.username
  password               = var.password
  db_name                = var.db_name
  multi_az               = false
  publicly_accessible    = var.publicly_accessible
  vpc_security_group_ids = var.security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  skip_final_snapshot    = true
}

output "db_endpoint" {
  value = aws_db_instance.db.endpoint
}