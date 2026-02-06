variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "network" {
  type = string
}

variable "ip_cidr_range" {
  type    = string
  default = null
}

resource "google_vpc_access_connector" "this" {
  name          = var.name
  region        = var.region
  network       = var.network
  ip_cidr_range = var.ip_cidr_range
}

output "id" {
  value = google_vpc_access_connector.this.id
}

output "name" {
  value = google_vpc_access_connector.this.name
}

