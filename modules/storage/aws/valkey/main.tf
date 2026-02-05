resource "aws_elasticache_serverless_cache" "this" {
  name        = var.name
  engine      = var.engine
  description = var.description

  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids

  tags = var.tags
}