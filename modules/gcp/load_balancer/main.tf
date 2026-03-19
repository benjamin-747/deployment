variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "lb_name" {
  type = string
}

variable "lb_domain" {
  type        = string
  description = "Domain name for the load balancer"
}

variable "routes" {
  type = map(object({
    host    = string
    service = string
  }))
}

resource "google_compute_region_network_endpoint_group" "neg" {
  for_each              = var.routes
  project               = var.project_id
  region                = var.region
  name                  = "${var.lb_name}-${each.key}-neg"
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = each.value.service
  }
}

resource "google_compute_backend_service" "bs" {
  for_each              = var.routes
  project               = var.project_id
  name                  = "${var.lb_name}-${each.key}-bs"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.neg[each.key].id
  }
}

locals {
  first_route_key = keys(var.routes)[0]
}

resource "google_compute_url_map" "url_map" {
  project = var.project_id
  name    = "${var.lb_name}-urlmap"

  default_service = google_compute_backend_service.bs[local.first_route_key].self_link

  dynamic "host_rule" {
    for_each = var.routes
    content {
      hosts        = [host_rule.value.host]
      path_matcher = host_rule.key
    }
  }

  dynamic "path_matcher" {
    for_each = var.routes
    content {
      name            = path_matcher.key
      default_service = google_compute_backend_service.bs[path_matcher.key].self_link
    }
  }
}


resource "google_compute_global_address" "ip" {
  project = var.project_id
  name    = "${var.lb_name}-ip"

  lifecycle {
    prevent_destroy = true
  }
}


resource "google_compute_managed_ssl_certificate" "cert" {
  project = var.project_id
  name    = "${var.lb_name}-cert"

  managed {
    domains = [
      for r in var.routes :
      r.host
    ]
  }
}

resource "google_compute_target_https_proxy" "proxy" {
  project = var.project_id
  name    = "${var.lb_name}-https-proxy"
  url_map = google_compute_url_map.url_map.id

  ssl_certificates = [
    google_compute_managed_ssl_certificate.cert.id
  ]
}

resource "google_compute_global_forwarding_rule" "https" {
  project               = var.project_id
  name                  = "${var.lb_name}-https-fr"
  target                = google_compute_target_https_proxy.proxy.id
  port_range            = "443"
  ip_address            = google_compute_global_address.ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# --- Outputs ---

output "lb_ip" {
  value = google_compute_global_address.ip.address
}
