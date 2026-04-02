

resource "google_sql_database_instance" "this" {
  name                = var.name
  database_version    = var.database_version
  region              = var.region
  deletion_protection = var.deletion_protection

  # Cloud SQL delete can return before Private Service Access fully releases the
  # instance; deleting google_service_networking_connection too early then fails.
  timeouts {
    create = "40m"
    update = "40m"
    delete = "60m"
  }

  settings {
    tier              = var.tier
    edition           = var.edition
    availability_type = var.availability_type
    disk_size         = var.disk_size
    disk_type         = var.disk_type

    backup_configuration {
      enabled = var.backup_enabled
    }

    ip_configuration {
      ipv4_enabled    = var.enable_public_ip
      private_network = var.private_network
    }
  }

}

resource "google_sql_database" "db" {
  name       = var.db_name
  instance   = google_sql_database_instance.this.name
  depends_on = [google_sql_database_instance.this]
}

resource "google_sql_user" "user" {
  name       = var.db_username
  instance   = google_sql_database_instance.this.name
  password   = var.db_password
  depends_on = [google_sql_database_instance.this]
}

