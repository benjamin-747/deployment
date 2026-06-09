# Register CLB backends: EKSCI private IPs, one host rule per clb_host_rules entry.

locals {
  clb_rule_backends = var.enable_eksci ? {
    for rule_name, rule in local.clb_host_rules : rule_name => [
      {
        bind_ip = module.eksci[rule.backend].private_ip
        port    = local.backend_services[rule.backend].port
      }
    ]
  } : {}
}

resource "tencentcloud_clb_attachment" "workload" {
  for_each = {
    for rule_name, backends in local.clb_rule_backends : rule_name => backends if length(backends) > 0
  }

  clb_id      = module.clb.clb_id
  listener_id = module.clb.active_listener_id
  rule_id     = module.clb.listener_rule_ids[each.key]

  dynamic "targets" {
    for_each = each.value
    content {
      eni_ip = targets.value.bind_ip
      port   = targets.value.port
      weight = 10
    }
  }

  depends_on = [module.clb, module.eksci]
}
