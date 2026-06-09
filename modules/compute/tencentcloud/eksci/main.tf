resource "tencentcloud_eks_container_instance" "this" {
  name                  = var.name
  vpc_id                = var.vpc_id
  subnet_id             = var.subnet_id
  security_groups       = var.security_group_ids
  cpu                   = var.cpu
  memory                = var.memory
  restart_policy        = var.restart_policy
  auto_create_eip       = var.auto_create_eip
  eip_max_bandwidth_out = var.auto_create_eip ? var.eip_bandwidth : null
  eip_delete_policy     = var.auto_create_eip ? var.eip_delete_policy : null

  container {
    name     = "app"
    image    = var.image
    cpu      = var.cpu
    memory   = var.memory
    env_vars = var.env_vars
  }
}
