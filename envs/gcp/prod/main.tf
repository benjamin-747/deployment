locals {
  enable_build_env = var.enable_build_env
  enable_gcs       = var.enable_gcs
  enable_cloud_sql = var.enable_cloud_sql
  enable_redis     = var.enable_redis
  enable_filestore = var.enable_filestore
  enable_apps      = var.enable_apps

  enable_private_networking = var.enable_private_networking
  vpc_connector_name        = var.vpc_connector_name != "" ? var.vpc_connector_name : "${var.name_prefix}-cr-conn"
}

# GKE related modules disabled/removed, Cloud Run introduced for app service

module "network" {
  count  = local.enable_private_networking ? 1 : 0
  source = "../../../modules/gcp/network"

  name_prefix              = var.name_prefix
  region                   = var.region
  network_name             = var.network_name
  subnet_name              = var.subnet_name
  subnet_cidr              = var.subnet_cidr
  pods_secondary_range     = var.pods_secondary_range
  services_secondary_range = var.services_secondary_range
}

module "artifact_registry" {
  count  = local.enable_build_env ? 1 : 0
  source = "../../../modules/gcp/artifact_registry"

  location  = var.artifact_registry_location
  repo_name = var.artifact_registry_repo
}

module "iam" {
  source = "../../../modules/gcp/iam"

  project_id       = var.project_id
  prefix           = coalesce(var.app_suffix, var.name_prefix)
  service_accounts = var.iam_service_accounts
}

module "monitoring" {
  source = "../../../modules/gcp/monitoring"

  project_id                  = var.project_id
  enable_logging              = var.enable_logging
  enable_monitoring           = var.enable_monitoring
  enable_alerts               = var.enable_alerts
  alert_notification_channels  = var.alert_notification_channels
  log_sink_name               = var.log_sink_name
  log_sink_destination        = var.log_sink_destination
}

module "gcs" {
  count  = local.enable_gcs ? 1 : 0
  source = "../../../modules/gcp/gcs"

  name                     = var.gcs_bucket
  location                 = var.region
  force_destroy            = var.gcs_force_destroy
  uniform_bucket_level_access = var.gcs_uniform_bucket_level_access
}

module "cloud_sql" {
  count  = local.enable_cloud_sql ? 1 : 0
  source = "../../../modules/gcp/cloud_sql"

  name                     = var.cloud_sql_instance_name
  database_version         = var.cloud_sql_database_version
  region                   = var.region
  tier                     = var.cloud_sql_tier
  disk_size                = var.cloud_sql_disk_size
  disk_type                = var.cloud_sql_disk_type
  availability_type        = var.cloud_sql_availability_type
  private_network          = local.enable_private_networking ? module.network[0].network_self_link : ""
  private_ip_prefix_length = var.cloud_sql_private_ip_prefix_length
  enable_private_service_connection = var.cloud_sql_enable_private_service_connection
  enable_public_ip         = var.cloud_sql_enable_public_ip
  db_name                  = var.cloud_sql_db_name
  db_username              = var.db_username
  db_password              = var.db_password
  backup_enabled           = var.cloud_sql_backup_enabled
  deletion_protection      = var.cloud_sql_deletion_protection
}

module "redis" {
  count  = local.enable_redis ? 1 : 0
  source = "../../../modules/gcp/redis"

  name                    = var.redis_instance_name
  region                  = var.region
  tier                    = var.redis_tier
  memory_size_gb          = var.redis_memory_size_gb
  network                 = local.enable_private_networking ? module.network[0].network_self_link : ""
  transit_encryption_mode = var.redis_transit_encryption_mode
}

module "filestore" {
  count  = local.enable_filestore ? 1 : 0
  source = "../../../modules/gcp/filestore"

  name           = var.filestore_instance_name
  location       = var.zone != "" ? var.zone : "${var.region}-b"
  network        = local.enable_private_networking ? module.network[0].network_self_link : ""
  tier           = var.filestore_tier
  capacity_gb    = var.filestore_capacity_gb
  file_share_name = var.filestore_file_share_name
  reserved_ip_range = var.filestore_reserved_ip_range
}

# Serverless VPC Access Connector for Cloud Run private egress
module "vpc_connector" {
  count  = local.enable_private_networking ? 1 : 0
  source = "../../../modules/gcp/vpc_connector"

  name          = local.vpc_connector_name
  region        = var.region
  network       = module.network[0].network_self_link
  ip_cidr_range = var.vpc_connector_cidr
}

# Cloud Run module for application service
module "app_cloud_run" {
  count        = local.enable_apps ? 1 : 0
  source       = "../../../modules/gcp/cloud_run"

  project_id   = var.project_id
  region       = var.region
  service_name = var.app_service_name
  image        = var.app_image
  env_vars     = var.app_env

  cpu            = var.app_cpu
  memory         = var.app_memory
  min_instances  = var.app_min_instances
  max_instances  = var.app_max_instances
  allow_unauth   = var.app_allow_unauth

  vpc_connector = local.enable_private_networking ? module.vpc_connector[0].name : null
  vpc_egress     = var.cloud_run_vpc_egress
}

module "ui_cloud_run" {
  count        = local.enable_apps && var.ui_service_name != "" ? 1 : 0
  source       = "../../../modules/gcp/cloud_run"

  project_id   = var.project_id
  region       = var.region
  service_name = var.ui_service_name
  image        = var.ui_image
  env_vars     = var.ui_env_vars

  cpu            = var.ui_cpu
  memory         = var.ui_memory
  min_instances  = var.ui_min_instances
  max_instances  = var.ui_max_instances
  allow_unauth   = var.ui_allow_unauth

  vpc_connector = local.enable_private_networking ? module.vpc_connector[0].name : null
  vpc_egress     = var.cloud_run_vpc_egress
}

# Outputs adjusted (removed GKE related ones)

output "artifact_registry_repo" {
  value = local.enable_build_env ? module.artifact_registry[0].repository : null
}

output "gcs_bucket_name" {
  value = local.enable_gcs ? module.gcs[0].bucket_name : null
}

output "cloud_sql_db_endpoint" {
  value = local.enable_cloud_sql ? module.cloud_sql[0].db_endpoint : null
}

output "cloud_sql_connection_name" {
  value = local.enable_cloud_sql ? module.cloud_sql[0].connection_name : null
}

output "redis_host" {
  value = local.enable_redis ? module.redis[0].host : null
}

output "redis_port" {
  value = local.enable_redis ? module.redis[0].port : null
}

output "filestore_instance_name" {
  value = local.enable_filestore ? module.filestore[0].instance_name : null
}

output "filestore_file_share_name" {
  value = local.enable_filestore ? module.filestore[0].file_share_name : null
}

output "filestore_ip_address" {
  value = local.enable_filestore ? module.filestore[0].ip_address : null
}

output "app_cloud_run_url" {
  value = local.enable_apps ? module.app_cloud_run[0].url : null
}

output "ui_cloud_run_url" {
  value = local.enable_apps && var.ui_service_name != "" ? module.ui_cloud_run[0].url : null
}

output "iam_service_accounts" {
  description = "Created service accounts with emails and names"
  value       = module.iam.service_accounts
}

output "iam_workload_identity_bindings" {
  description = "Workload Identity bindings (K8s SA -> GCP SA)"
  value       = module.iam.workload_identity_bindings
}

output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "monitoring_logging_api_enabled" {
  description = "Whether Logging/Monitoring APIs are enabled"
  value       = module.monitoring.logging_api_enabled && module.monitoring.monitoring_api_enabled
}
