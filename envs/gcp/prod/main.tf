locals {

  enable_private_networking = var.enable_private_networking

  # Strictly use app_name for resource naming (Convention over Configuration)
  network_name          = "${var.app_name}-vpc3"
  subnet_name           = "${var.app_name}-subnet"
  gcs_bucket            = "${var.app_name}-storage"
  redis_instance_name   = var.redis_instance_name != "" ? var.redis_instance_name : "${var.app_name}-redis"
  mono_service_name     = "${var.app_name}-mono"
  ui_service_name       = "${var.app_name}-ui"
  orion_service_name    = "${var.app_name}-orion"
  campsite_service_name = "${var.app_name}-campsite"
  notesync_service_name = "${var.app_name}-notesync"
  vpc_connector_name    = "${var.app_name}-cr-conn"

  enable_lb = var.enable_lb
  cloud_run_vpc_egress = "all-traffic"
}



# Network module
module "network" {
  count  = local.enable_private_networking ? 1 : 0
  source = "../../../modules/gcp/network"

  app_name                 = var.app_name
  region                   = var.region
  network_name             = local.network_name
  subnet_name              = local.subnet_name
  subnet_cidr              = var.subnet_cidr
  pods_secondary_range     = var.pods_secondary_range
  services_secondary_range = var.services_secondary_range
}

# IAM module
module "iam" {
  source = "../../../modules/gcp/iam"

  project_id       = var.project_id
  app_name         = coalesce(var.app_suffix, var.app_name)
  service_accounts = var.iam_service_accounts
}

# Monitoring module
module "monitoring" {
  source = "../../../modules/gcp/monitoring"

  project_id                  = var.project_id
  app_name                    = var.app_name
  enable_logging              = var.enable_logging
  enable_monitoring           = var.enable_monitoring
  enable_alerts               = var.enable_alerts
  alert_notification_channels = var.alert_notification_channels
  log_sink_name               = var.log_sink_name
  log_sink_destination        = var.log_sink_destination
}

# GCS module
module "gcs" {
  source = "../../../modules/gcp/gcs"

  name                        = local.gcs_bucket
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
  tier                = "db-f1-micro"
  disk_size           = 10
  disk_type           = "PD_SSD"
  availability_type   = "ZONAL"
  private_network     = local.enable_private_networking ? module.network[0].network_self_link : ""
  enable_public_ip    = var.cloud_sql_enable_public_ip
  db_name             = var.cloud_sql_pg_name
  db_username         = var.db_username
  db_password         = var.db_password
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

  private_network  = local.enable_private_networking ? module.network[0].network_self_link : ""
  enable_public_ip = var.cloud_sql_enable_public_ip

  db_name     = var.cloud_sql_pg_name
  db_username = var.db_username
  db_password = var.db_password

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
  network                 = local.enable_private_networking ? module.network[0].network_self_link : ""
  transit_encryption_mode = var.redis_transit_encryption_mode
}


# Private DNS
module "private_dns" {
  source = "../../../modules/gcp/private_dns"

  network           = local.enable_private_networking ? module.network[0].network_self_link : ""
  zone_name         = "internal-zone"
  dns_name          = "internal.${var.base_domain}."
  redis_record_name = "redis.internal.${var.base_domain}."
  redis_ip          = module.redis.host
  mysql_record_name = "mysql.internal.${var.base_domain}."
  mysql_ip          = module.cloud_sql_mysql.db_endpoint
}


# Serverless VPC Access Connector
module "vpc_connector" {
  count  = local.enable_private_networking ? 1 : 0
  source = "../../../modules/gcp/vpc_connector"

  name          = local.vpc_connector_name
  region        = var.region
  network       = module.network[0].network_self_link
  ip_cidr_range = var.vpc_connector_cidr
}

# Cloud Run: Backend
module "mono_cloud_run" {
  source = "../../../modules/gcp/cloud_run"

  project_id   = var.project_id
  region       = var.region
  service_name = local.mono_service_name
  image        = var.app_image
  env_vars = {
    MEGA_LOG__LEVEL                  = "info"
    MEGA_DATABASE__DB_URL            = "postgres://${var.db_username}:${var.db_password}@${module.cloud_sql_pg.db_endpoint}:5432/${var.cloud_sql_pg_name}"
    MEGA_MONOREPO__STORAGE_TYPE      = "gcs"
    MEGA_BUILD__ORION_SERVER         = "https://orion.${var.base_domain}"
    MEGA_LFS__STORAGE_TYPE           = "gcs"
    MEGA_LFS__HTTP_URL               = "https://git.${var.base_domain}"
    MEGA_OBJECT_STORAGE__GCS__BUCKET = "${local.gcs_bucket}"
    MEGA_OAUTH__CAMPSITE_API_DOMAIN  = "https://api.${var.base_domain}"
    MEGA_OAUTH__ALLOWED_CORS_ORIGINS = "https://app.${var.base_domain}"
    MEGA_REDIS__URL                  = "redis://${module.redis.host}:6379"
  }
  cpu            = "1"
  memory         = "1024Mi"
  min_instances  = 1
  max_instances  = 2
  allow_unauth   = true
  container_port = 8000

  vpc_connector = local.enable_private_networking ? module.vpc_connector[0].name : null
  vpc_egress    = local.cloud_run_vpc_egress
}

# Cloud Run: UI
module "ui_cloud_run" {
  source = "../../../modules/gcp/cloud_run"

  project_id   = var.project_id
  region       = var.region
  service_name = local.ui_service_name
  image        = var.ui_image
  env_vars     = var.ui_env_vars

  cpu            = "1"
  memory         = "512Mi"
  min_instances  = 0
  max_instances  = 2
  allow_unauth   = true
  container_port = 3000

  vpc_connector = local.enable_private_networking ? module.vpc_connector[0].name : null
  vpc_egress    = local.cloud_run_vpc_egress
}

# Cloud Run: Orion Server
module "orion_cloud_run" {
  source = "../../../modules/gcp/cloud_run"

  project_id   = var.project_id
  region       = var.region
  service_name = local.orion_service_name
  image        = var.orion_image
  env_vars = {
    # MEGA_CONFIG                     = "/opt/mega/etc/config.toml"
    MEGA_ORION_SERVER__DB_URL        = "postgres://${var.db_username}:${var.db_password}@${module.cloud_sql_pg.db_endpoint}:5432/${var.cloud_sql_pg_name}"
    MEGA_ORION_SERVER__MONOBASE_URL  = "https://git.${var.base_domain}"
    MEGA_ORION_SERVER__STORAGE_TYPE  = "gcs"
    MEGA_OAUTH__ALLOWED_CORS_ORIGINS = "https://app.${var.base_domain}"
  }

  cpu            = "1"
  memory         = "512Mi"
  min_instances  = 0
  max_instances  = 2
  allow_unauth   = true
  container_port = 8004

  vpc_connector = local.enable_private_networking ? module.vpc_connector[0].name : null
  vpc_egress    = local.cloud_run_vpc_egress
}

# Cloud Run: Campsite
module "campsite_cloud_run" {
  source = "../../../modules/gcp/cloud_run"

  project_id   = var.project_id
  region       = var.region
  service_name = local.campsite_service_name
  image        = var.campsite_image
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

  cpu               = "1"
  memory            = "1024Mi"
  min_instances     = 1
  max_instances     = 2
  allow_unauth      = true
  container_port    = 8080
  enable_migrations = true
  vpc_connector     = local.enable_private_networking ? module.vpc_connector[0].name : null
  vpc_egress        = local.cloud_run_vpc_egress
}

# Load Balancer module
module "lb_backends" {
  count  = var.enable_lb ? 1 : 0
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

output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "monitoring_logging_api_enabled" {
  description = "Whether Logging/Monitoring APIs are enabled"
  value       = module.monitoring.logging_api_enabled && module.monitoring.monitoring_api_enabled
}

output "lb_ip" {
  description = "The public Anycast IP address of the load balancer"
  value       = var.enable_lb ? module.lb_backends[0].lb_ip : null
}
