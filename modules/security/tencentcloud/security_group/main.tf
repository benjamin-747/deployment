resource "tencentcloud_security_group" "this" {
  name        = var.name
  description = "Managed by Terraform (${var.name})"
  tags        = var.tags
}

# A single rule_set must be exclusive per security group (do not declare
# additional rule resources for the same SG elsewhere).
resource "tencentcloud_security_group_rule_set" "this" {
  security_group_id = tencentcloud_security_group.this.id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      action      = ingress.value.action
      protocol    = ingress.value.protocol
      port        = ingress.value.port
      cidr_block  = ingress.value.cidr_block
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      action      = egress.value.action
      protocol    = egress.value.protocol
      port        = egress.value.port
      cidr_block  = egress.value.cidr_block
      description = egress.value.description
    }
  }
}
