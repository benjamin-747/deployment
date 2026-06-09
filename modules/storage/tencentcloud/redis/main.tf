# Resolve the AZ of the first subnet so callers only pass the VPC subnet ID list.
data "tencentcloud_vpc_subnets" "selected" {
  subnet_id = var.subnet_ids[0]
}

locals {
  subnet_id         = var.subnet_ids[0]
  availability_zone = data.tencentcloud_vpc_subnets.selected.instance_list[0].availability_zone
}

resource "tencentcloud_redis_instance" "this" {
  name              = var.name
  availability_zone = local.availability_zone
  type_id           = var.type_id
  mem_size          = var.memory_size
  port              = var.port
  vpc_id            = var.vpc_id
  subnet_id         = local.subnet_id
  security_groups   = var.security_group_ids
  password          = var.password

  # Single-AZ deployment: keep replicas in the primary AZ and do not set
  # replica_zone_ids (which would spread replicas across availability zones).
  redis_replicas_num = var.replicas_num

  tags = var.tags
}
