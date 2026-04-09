locals {

  # Strictly use app_name for resource naming (Convention over Configuration)
  network_name          = "${var.app_name}-vpc4"
  subnet_name           = "${var.app_name}-subnet"
  gcs_bucket_name       = "${var.app_name}-storage"
  redis_instance_name   = "${var.app_name}-redis"
  mono_service_name     = "${var.app_name}-mono"
  ui_service_name       = "${var.app_name}-ui"
  orion_service_name    = "${var.app_name}-orion"
  campsite_service_name = "${var.app_name}-campsite"
  notesync_service_name = "${var.app_name}-notesync"
  vpc_connector_db_name = "${var.app_name}-cr-conn-db"

  # Only route private ranges through the Serverless VPC Connector
  cloud_run_vpc_egress = "private-ranges-only"

  cloud_run_resources_map = {
    for r in var.cloud_run_resources :
    r.service => r
  }

  # Single line per key; trailing newline breaks metadata ssh-keys parsing.
  orion_vm_ssh_public_key = chomp(tls_private_key.orion_vm_key.public_key_openssh)

  # Ensure the private key file is written deterministically under this env directory.
  # If the user provides an absolute path, respect it.
  orion_vm_private_key_file_effective = startswith(var.orion_vm_private_key_file_path, "/") ? var.orion_vm_private_key_file_path : "${path.module}/${var.orion_vm_private_key_file_path}"
}

# Network module (merged back into prod state)
module "network" {
  source = "../../../modules/gcp/network"

  app_name     = var.app_name
  region       = var.region
  network_name = local.network_name
  subnet_name  = local.subnet_name
  subnet_cidr  = var.vpc_subnet_cidr
}

# SSH to Orion VM only (VPC default had no allow_ssh; broad network.allow_ssh would open 22 for all VMs).
resource "google_compute_firewall" "orion_allow_ssh" {
  project = var.project_id
  name    = "${var.app_name}-orion-allow-ssh"
  network = module.network.network_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.orion_vm_ssh_allowed_cidrs
  target_tags   = ["orion-ssh"]
}

# IAM module
module "iam" {
  source = "../../../modules/gcp/iam"

  project_id       = var.project_id
  app_name         = var.iam_app_name_override != "" ? var.iam_app_name_override : var.app_name
  service_accounts = var.iam_service_accounts
}

# Monitoring module
module "monitoring" {
  source = "../../../modules/gcp/monitoring"

  project_id                  = var.project_id
  app_name                    = var.app_name
  alert_notification_channels = var.monitoring_alert_notification_channel_ids
  log_sink_name               = var.monitoring_log_sink_name
  log_sink_destination        = var.monitoring_log_sink_destination
}

# GCS module
module "gcs" {
  source = "../../../modules/gcp/gcs"

  name                        = local.gcs_bucket_name
  location                    = var.region
  force_destroy               = var.gcs_force_destroy
  uniform_bucket_level_access = var.gcs_uniform_bucket_level_access
}

# Cloud SQL module
module "cloud_sql_pg" {
  source = "../../../modules/gcp/cloud_sql"

  name                = "${var.app_name}-pg"
  database_version    = "POSTGRES_17"
  region              = var.region
  tier                = var.cloud_sql_pg_tier
  disk_size           = var.cloud_sql_pg_disk_size_gb
  disk_type           = "PD_SSD"
  availability_type   = "ZONAL"
  private_network     = module.network.network_self_link
  enable_public_ip    = var.cloud_sql_enable_public_ip
  db_name             = var.cloud_sql_pg_name
  db_username         = var.cloud_sql_username
  db_password         = var.cloud_sql_password
  backup_enabled      = false
  deletion_protection = false
  depends_on          = [module.network]

}

module "cloud_sql_mysql" {
  source = "../../../modules/gcp/cloud_sql"

  name              = "${var.app_name}-mysql"
  database_version  = "MYSQL_8_4"
  region            = var.region
  tier              = "db-f1-micro"
  disk_size         = 10
  disk_type         = "PD_SSD"
  availability_type = "ZONAL"

  private_network  = module.network.network_self_link
  enable_public_ip = var.cloud_sql_enable_public_ip

  db_name     = var.cloud_sql_mysql_name
  db_username = var.cloud_sql_username
  db_password = var.cloud_sql_password

  backup_enabled      = false
  deletion_protection = false
  depends_on          = [module.network]

}

# Redis module
module "redis" {
  source                  = "../../../modules/gcp/redis"
  project_id              = var.project_id
  name                    = local.redis_instance_name
  region                  = var.region
  memory_size_gb          = var.redis_memory_size_gb
  network                 = module.network.network_self_link
  transit_encryption_mode = var.redis_transit_encryption_mode
}


# Private DNS
module "private_dns" {
  source = "../../../modules/gcp/private_dns"

  network           = module.network.network_self_link
  zone_name         = "internal-zone"
  dns_name          = "internal.${var.base_domain}."
  redis_record_name = "redis.internal.${var.base_domain}."
  redis_ip          = module.redis.host
  mysql_record_name = "mysql.internal.${var.base_domain}."
  mysql_ip          = module.cloud_sql_mysql.db_endpoint
}


# Serverless VPC Access Connector
module "vpc_connector_db" {
  source = "../../../modules/gcp/vpc_connector"

  name          = local.vpc_connector_db_name
  region        = var.region
  network       = module.network.network_self_link
  ip_cidr_range = var.vpc_serverless_connector_cidr
}

# Cloud Run: Backend
module "mono_cloud_run" {
  source = "../../../modules/gcp/cloud_run"

  project_id   = var.project_id
  region       = var.region
  service_name = local.mono_service_name
  image        = "us-central1-docker.pkg.dev/infra-20250121-20260121-0235/mega/mono-engine:latest-amd64"
  env_vars = {
    MEGA_LOG__LEVEL                       = "info"
    MEGA_LOG__WITH_ANSI                   = false
    MEGA_PACK__SAVE_ENTRY_CONCURRENCY     = 8
    MEGA_DATABASE__DB_URL                 = "postgres://${var.cloud_sql_username}:${var.cloud_sql_password}@${module.cloud_sql_pg.db_endpoint}:5432/${var.cloud_sql_pg_name}"
    MEGA_MONOREPO__STORAGE_TYPE           = "gcs"
    MEGA_BUILD__ORION_SERVER              = "https://orion.${var.base_domain}"
    MEGA_LFS__STORAGE_TYPE                = "gcs"
    MEGA_LFS__HTTP_URL                    = "https://git.${var.base_domain}"
    MEGA_OBJECT_STORAGE__GCS__BUCKET      = local.gcs_bucket_name
    MEGA_OAUTH__CAMPSITE_API_DOMAIN       = "https://api.${var.base_domain}"
    MEGA_OAUTH__ALLOWED_CORS_ORIGINS      = "https://app.${var.base_domain}"
    MEGA_REDIS__URL                       = "redis://${module.redis.host}:6379"
    MEGA_AUTHENTICATION__ENABLE_HTTP_AUTH = true
  }
  cpu            = local.cloud_run_resources_map["mono"].cpu
  memory         = local.cloud_run_resources_map["mono"].memory
  min_instances  = 1
  max_instances  = 1
  allow_unauth   = true
  container_port = 8000

  vpc_connector = module.vpc_connector_db.name
  vpc_egress    = local.cloud_run_vpc_egress
}

# Cloud Run: UI
module "ui_cloud_run" {
  source = "../../../modules/gcp/cloud_run"

  project_id   = var.project_id
  region       = var.region
  service_name = local.ui_service_name
  image        = "us-central1-docker.pkg.dev/infra-20250121-20260121-0235/mega/mega-ui:buck2hub-latest-amd64"
  env_vars     = var.cloud_run_ui_env

  cpu            = local.cloud_run_resources_map["ui"].cpu
  memory         = local.cloud_run_resources_map["ui"].memory
  min_instances  = 1
  max_instances  = 1
  allow_unauth   = true
  container_port = 3000

  # UI 只需要公网访问，不访问私网资源，不必走 VPC Connector
  vpc_connector = null
  vpc_egress    = null
}

module "mega-web-sync-app" {
  source = "../../../modules/gcp/cloud_run"

  project_id   = var.project_id
  region       = var.region
  service_name = local.notesync_service_name
  image        = "us-central1-docker.pkg.dev/infra-20250121-20260121-0235/mega/web-sync-server:latest"
  env_vars = {
    API_URL  = "https://api.${var.base_domain}"
    NODE_ENV = "production"
  }

  cpu            = local.cloud_run_resources_map["notesync"].cpu
  memory         = local.cloud_run_resources_map["notesync"].memory
  min_instances  = 0
  max_instances  = 1
  allow_unauth   = true
  container_port = 9000

  # Notesync 只访问公开 API，不访问私网资源，不必走 VPC Connector
  vpc_connector = null
  vpc_egress    = null
}


# Cloud Run: Orion Server
module "orion_cloud_run" {
  source = "../../../modules/gcp/cloud_run"

  project_id   = var.project_id
  region       = var.region
  service_name = local.orion_service_name
  image        = "us-central1-docker.pkg.dev/infra-20250121-20260121-0235/mega/orion-server:latest-amd64"
  env_vars = {
    MEGA_ORION_SERVER__DB_URL        = "postgres://${var.cloud_sql_username}:${var.cloud_sql_password}@${module.cloud_sql_pg.db_endpoint}:5432/${var.cloud_sql_pg_name}"
    MEGA_ORION_SERVER__MONOBASE_URL  = "https://git.${var.base_domain}"
    MEGA_ORION_SERVER__STORAGE_TYPE  = "gcs"
    MEGA_OAUTH__ALLOWED_CORS_ORIGINS = "https://app.${var.base_domain}"
    MEGA_OBJECT_STORAGE__GCS__BUCKET = local.gcs_bucket_name
  }

  cpu            = local.cloud_run_resources_map["orion"].cpu
  memory         = local.cloud_run_resources_map["orion"].memory
  min_instances  = 0
  max_instances  = 1
  allow_unauth   = true
  container_port = 8004

  vpc_connector = module.vpc_connector_db.name
  vpc_egress    = local.cloud_run_vpc_egress
}

# Cloud Run: Campsite
module "campsite_cloud_run" {
  source = "../../../modules/gcp/cloud_run"

  project_id   = var.project_id
  region       = var.region
  service_name = local.campsite_service_name
  image        = "us-central1-docker.pkg.dev/infra-20250121-20260121-0235/mega/campsite-api:latest-amd64"
  env_vars = {
    DEV_APP_URL      = "https://app.${var.base_domain}"
    RAILS_ENV        = "staging-buck2hub"
    RAILS_MASTER_KEY = "${var.rails_master_key}"
    SERVER_COMMAND   = "bundle exec puma"
  }

  depends_on = [
    module.cloud_sql_mysql,
    module.redis
  ]

  cpu               = local.cloud_run_resources_map["campsite"].cpu
  memory            = local.cloud_run_resources_map["campsite"].memory
  min_instances     = 1
  max_instances     = 1
  allow_unauth      = true
  container_port    = 8080
  enable_migrations = true
  vpc_connector     = module.vpc_connector_db.name
  vpc_egress        = local.cloud_run_vpc_egress
}

# Load Balancer module
module "lb_backends" {
  count  = var.load_balancer_enabled ? 1 : 0
  source = "../../../modules/gcp/load_balancer"

  project_id = var.project_id
  region     = var.region
  lb_name    = "${var.app_name}-lb"
  routes = {
    git = {
      host    = "git.${var.base_domain}"
      service = "${local.mono_service_name}"
    },
    app = {
      host    = "app.${var.base_domain}"
      service = "${local.ui_service_name}"
    }
    auth = {
      host    = "auth.${var.base_domain}"
      service = "${local.campsite_service_name}"
    }
    api = {
      host    = "api.${var.base_domain}"
      service = "${local.campsite_service_name}"
    }
    orion = {
      host    = "orion.${var.base_domain}"
      service = "${local.orion_service_name}"
    }
    sync = {
      host    = "sync.${var.base_domain}"
      service = "${local.notesync_service_name}"
    }

  }
  lb_domain = var.base_domain
}

output "gcs_bucket_name" {
  value = module.gcs.bucket_name
}

output "cloud_sql_pg_endpoint" {
  value = module.cloud_sql_pg.db_endpoint
}

output "cloud_sql_mysql_endpoint" {
  value = module.cloud_sql_mysql.db_endpoint
}

output "cloud_sql_connection_name" {
  value = module.cloud_sql_pg.connection_name
}

output "redis_host" {
  value = module.redis.host
}


output "mono_cloud_run_url" {
  value = module.mono_cloud_run.url
}

output "ui_cloud_run_url" {
  value = module.ui_cloud_run.url
}

output "orion_cloud_run_url" {
  value = module.orion_cloud_run.url
}

output "campsite_cloud_run_url" {
  value = module.campsite_cloud_run.url
}

output "lb_ip" {
  description = "The public Anycast IP address of the load balancer"
  value       = var.load_balancer_enabled ? module.lb_backends[0].lb_ip : null
}

output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "orion_vm_public_ip" {
  value = google_compute_instance.orion_client_vm.network_interface[0].access_config[0].nat_ip
}

output "orion_vm_private_key_pem" {
  value     = tls_private_key.orion_vm_key.private_key_pem
  sensitive = true
}

output "orion_vm_private_key_openssh" {
  description = "OpenSSH private key for SSH'ing into the Orion client VM"
  value       = tls_private_key.orion_vm_key.private_key_openssh
  sensitive   = true
}


resource "tls_private_key" "orion_vm_key" {
  algorithm = "ED25519"
}

resource "google_compute_address" "orion_vm_ip" {
  name   = "${var.app_name}-orion-vm-ip"
  region = var.region
}

resource "google_compute_instance" "orion_client_vm" {
  name                      = "${var.app_name}-orion-client-vm"
  machine_type              = var.orion_vm_machine_type
  zone                      = var.zone
  allow_stopping_for_update = true
  tags                      = ["orion-ssh"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = var.orion_vm_boot_disk_size_gb
    }
  }

  network_interface {
    # Use module outputs so the VM attaches to the subnet Terraform created in var.region
    # (short names alone resolve against provider region and can mismatch if state/GCP drift).
    network    = module.network.network_self_link
    subnetwork = module.network.subnetwork_self_link
    access_config {
      nat_ip = google_compute_address.orion_vm_ip.address
    }
  }

  metadata = {
    # ubuntu: always present on ubuntu-os-cloud images; orion: used by startup/services.
    # Same key on both avoids login failures when orion is created late or metadata line breaks.
    ssh-keys       = <<-EOT
ubuntu:${local.orion_vm_ssh_public_key}
orion:${local.orion_vm_ssh_public_key}
EOT
    startup-script = file("${path.module}/scripts/startup-orion-client.sh")
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.orion_vm_key.private_key_openssh
    host        = self.network_interface[0].access_config[0].nat_ip
  }



  service_account {
    scopes = ["cloud-platform"]
  }
}

resource "local_sensitive_file" "orion_vm_private_key_openssh" {
  filename        = abspath(pathexpand(local.orion_vm_private_key_file_effective))
  content         = tls_private_key.orion_vm_key.private_key_openssh
  file_permission = "0600"
}

