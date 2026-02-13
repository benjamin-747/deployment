resource "google_redis_instance" "this" {
  name                    = var.name
  project                 = var.project_id
  region                  = var.region
  tier                    = "BASIC"
  memory_size_gb          = var.memory_size_gb
  authorized_network      = var.network
  transit_encryption_mode = var.transit_encryption_mode
}
