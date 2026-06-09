# EKSCI: deploy all gitmono services as container instances (default when enable_eksci = true).

locals {
  eksci_service_keys = sort(keys(local.workloads_all))

  eksci_subnet_for = {
    for i, name in local.eksci_service_keys : name =>
    module.vpc.public_subnet_ids[i % length(module.vpc.public_subnet_ids)]
  }

  # EKSCI uses core/GiB floats; workloads_all carries K8s quantities (500m, 1024Mi).
  eksci_cpu_gib = {
    for name, cfg in local.workloads_all : name => {
      cpu = (
        can(regex("m$", cfg.cpu)) ? tonumber(replace(cfg.cpu, "m", "")) / 1000 : tonumber(cfg.cpu)
      )
      memory = (
        can(regex("Mi$", cfg.memory)) ? tonumber(replace(cfg.memory, "Mi", "")) / 1024 :
        can(regex("Gi$", cfg.memory)) ? tonumber(replace(cfg.memory, "Gi", "")) :
        tonumber(cfg.memory)
      )
    }
  }

  eksci_env_vars = {
    for name, cfg in local.workloads_all : name => {
      for env in cfg.environment : env.name => env.value
    }
  }
}

module "eksci" {
  for_each = var.enable_eksci ? local.workloads_all : {}
  source   = "../../../modules/compute/tencentcloud/eksci"

  name               = "${var.app_suffix}-${replace(each.key, "_", "-")}"
  vpc_id             = module.vpc.vpc_id
  subnet_id          = local.eksci_subnet_for[each.key]
  security_group_ids = [module.security_group.security_group_id]

  image    = each.value.image
  cpu      = local.eksci_cpu_gib[each.key].cpu
  memory   = local.eksci_cpu_gib[each.key].memory
  env_vars = local.eksci_env_vars[each.key]

  auto_create_eip   = var.enable_pod_eip
  eip_bandwidth     = var.pod_eip_bandwidth
  eip_delete_policy = true
}
