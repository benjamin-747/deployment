output "network_self_link" {
  value = google_compute_network.this.self_link
}

output "network_id" {
  value = google_compute_network.this.id
}

output "subnetwork_self_link" {
  value = local.use_multi_subnets ? (
    length(google_compute_subnetwork.private) > 0 ? google_compute_subnetwork.private[0].self_link : google_compute_subnetwork.public[0].self_link
  ) : google_compute_subnetwork.this[0].self_link
}

output "subnetwork_name" {
  value = local.use_multi_subnets ? (
    length(google_compute_subnetwork.private) > 0 ? google_compute_subnetwork.private[0].name : google_compute_subnetwork.public[0].name
  ) : google_compute_subnetwork.this[0].name
}

output "public_subnetwork_names" {
  value = local.use_multi_subnets ? [for s in google_compute_subnetwork.public : s.name] : []
}

output "private_subnetwork_names" {
  value = local.use_multi_subnets ? [for s in google_compute_subnetwork.private : s.name] : []
}

output "public_subnetwork_self_links" {
  value = local.use_multi_subnets ? [for s in google_compute_subnetwork.public : s.self_link] : []
}

output "private_subnetwork_self_links" {
  value = local.use_multi_subnets ? [for s in google_compute_subnetwork.private : s.self_link] : []
}

output "router_name" {
  value = var.create_nat && (local.use_multi_subnets ? local.has_private_subnets : true) ? google_compute_router.this[0].name : null
}

output "nat_name" {
  value = var.create_nat && (local.use_multi_subnets ? local.has_private_subnets : true) ? google_compute_router_nat.this[0].name : null
}
