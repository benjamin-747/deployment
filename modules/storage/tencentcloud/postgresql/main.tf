# The instance must sit in a single subnet/AZ. Resolve the AZ of the first
# subnet so callers only need to pass the VPC's subnet ID list.
data "tencentcloud_vpc_subnets" "selected" {
  subnet_id = var.subnet_ids[0]
}

locals {
  subnet_id         = var.subnet_ids[0]
  availability_zone = data.tencentcloud_vpc_subnets.selected.instance_list[0].availability_zone
}

resource "tencentcloud_postgresql_instance" "this" {
  name              = var.name
  availability_zone = local.availability_zone
  charge_type       = var.charge_type
  vpc_id            = var.vpc_id
  subnet_id         = local.subnet_id
  db_major_version  = var.db_major_version
  root_user         = var.db_username
  root_password     = var.db_password
  charset           = var.charset
  cpu               = var.cpu > 0 ? var.cpu : null
  memory            = var.memory
  storage           = var.storage
  security_groups   = var.security_group_ids
  tags              = var.tags
}
