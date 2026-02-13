locals {
  has_public_subnets  = length(var.public_subnet_cidrs) > 0
  has_private_subnets = length(var.private_subnet_cidrs) > 0
  use_multi_subnets   = local.has_public_subnets || local.has_private_subnets

  public_subnet_map  = { for idx, cidr in var.public_subnet_cidrs : idx => cidr }
  private_subnet_map = { for idx, cidr in var.private_subnet_cidrs : idx => cidr }

  default_gke_node_tags   = ["${var.app_name}-gke"]
  effective_gke_node_tags = length(var.gke_node_tags) > 0 ? var.gke_node_tags : local.default_gke_node_tags

  health_check_port_numbers = [for p in var.health_check_ports : tonumber(p)]
}

resource "google_compute_network" "this" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "this" {
  count = local.use_multi_subnets ? 0 : 1

  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.this.id

  secondary_ip_range {
    range_name    = "${var.app_name}-pods"
    ip_cidr_range = var.pods_secondary_range
  }

  secondary_ip_range {
    range_name    = "${var.app_name}-services"
    ip_cidr_range = var.services_secondary_range
  }
}

resource "google_compute_subnetwork" "public" {
  for_each = local.use_multi_subnets ? local.public_subnet_map : {}

  name          = "${var.network_name}-public-${each.key}"
  ip_cidr_range = each.value
  region        = var.region
  network       = google_compute_network.this.id
}

resource "google_compute_subnetwork" "private" {
  for_each = local.use_multi_subnets ? local.private_subnet_map : {}

  name                     = "${var.network_name}-private-${each.key}"
  ip_cidr_range            = each.value
  region                   = var.region
  network                  = google_compute_network.this.id
  private_ip_google_access = var.enable_private_google_access
}

resource "google_compute_router" "this" {
  count = var.create_nat && (local.use_multi_subnets ? local.has_private_subnets : true) ? 1 : 0

  name    = "${var.app_name}-router"
  network = google_compute_network.this.id
  region  = var.region
}

resource "google_compute_router_nat" "this" {
  count = var.create_nat && (local.use_multi_subnets ? local.has_private_subnets : true) ? 1 : 0

  name                   = "${var.app_name}-nat"
  router                 = google_compute_router.this[0].name
  region                 = var.region
  nat_ip_allocate_option = "AUTO_ONLY"

  source_subnetwork_ip_ranges_to_nat = local.use_multi_subnets ? "LIST_OF_SUBNETWORKS" : "ALL_SUBNETWORKS_ALL_IP_RANGES"

  dynamic "subnetwork" {
    for_each = local.use_multi_subnets ? google_compute_subnetwork.private : {}
    content {
      name                    = subnetwork.value.self_link
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "allow_internal" {
  name    = "${var.network_name}-allow-internal"
  network = google_compute_network.this.self_link

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr]
}

resource "google_compute_firewall" "allow_ssh" {
  count   = var.allow_ssh ? 1 : 0
  name    = "${var.network_name}-allow-ssh"
  network = google_compute_network.this.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.network_name}-allow-health-checks"
  network = google_compute_network.this.self_link

  allow {
    protocol = "tcp"
    ports    = var.health_check_ports
  }

  source_ranges = var.health_check_source_ranges
  target_tags   = local.effective_gke_node_tags
}


resource "google_compute_global_address" "private_service_range" {
  name          = "cloudsql-db-private-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.this.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.this.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]
}
