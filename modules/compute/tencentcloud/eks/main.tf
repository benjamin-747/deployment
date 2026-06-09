locals {
  # In VPC-CNI mode cluster_max_service_num must match the service_cidr capacity.
  service_cidr_mask = tonumber(split("/", var.service_cidr)[1])
  max_service_num   = pow(2, 32 - local.service_cidr_mask)

  # One super node per subnet; fall back to all cluster subnets when not overridden.
  serverless_subnets = length(var.serverless_subnet_ids) > 0 ? var.serverless_subnet_ids : var.subnet_ids
}

resource "tencentcloud_kubernetes_cluster" "this" {
  cluster_name        = var.name
  cluster_desc        = "Managed by Terraform (${var.name})"
  cluster_deploy_type = "MANAGED_CLUSTER"
  cluster_version     = var.k8s_version != "" ? var.k8s_version : null
  cluster_level       = "L5"
  cluster_ipvs        = true

  vpc_id                  = var.vpc_id
  network_type            = "VPC-CNI"
  vpc_cni_type            = "tke-route-eni"
  eni_subnet_ids          = var.subnet_ids
  service_cidr            = var.service_cidr
  cluster_max_service_num = local.max_service_num
  cluster_max_pod_num     = var.cluster_max_pod_num

  tags = var.tags
}

resource "tencentcloud_kubernetes_serverless_node_pool" "this" {
  cluster_id         = tencentcloud_kubernetes_cluster.this.id
  name               = "${var.name}-serverless"
  security_group_ids = var.security_group_ids

  dynamic "serverless_nodes" {
    for_each = local.serverless_subnets
    content {
      display_name = "${var.name}-${serverless_nodes.key + 1}"
      subnet_id    = serverless_nodes.value
    }
  }

  labels = {
    workload = "serverless"
  }
}

resource "tencentcloud_kubernetes_cluster_endpoint" "public" {
  count = var.cluster_public_access ? 1 : 0

  cluster_id                      = tencentcloud_kubernetes_cluster.this.id
  cluster_internet                = true
  cluster_internet_security_group = length(var.security_group_ids) > 0 ? var.security_group_ids[0] : null

  depends_on = [tencentcloud_kubernetes_serverless_node_pool.this]
}
