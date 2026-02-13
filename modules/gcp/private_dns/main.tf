# --- Private DNS Zone ---
resource "google_dns_managed_zone" "this" {
  name     = var.zone_name
  dns_name = var.dns_name
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = var.network
    }
  }
}

# --- Redis DNS Record ---
resource "google_dns_record_set" "redis" {
  name         = var.redis_record_name
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.this.name

  rrdatas = [var.redis_ip]
}

# --- MySQL DNS Record ---
resource "google_dns_record_set" "mysql" {
  name         = var.mysql_record_name
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.this.name

  rrdatas = [var.mysql_ip]
}

# --- Outputs ---
output "zone_name" {
  value = google_dns_managed_zone.this.name
}

output "redis_fqdn" {
  value = google_dns_record_set.redis.name
}

output "mysql_fqdn" {
  value = google_dns_record_set.mysql.name
}