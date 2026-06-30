module "stack" {
  source = "../../../modules/compute/kubernetes/gitmono_stack"

  namespace            = var.namespace
  ingress_class_name   = var.ingress_class_name
  base_domain          = var.base_domain
  app_subdomains       = var.app_subdomains
  app_alias_subdomains = var.app_alias_subdomains
  cors_allowed_origins = var.cors_allowed_origins
  cratespro_url        = var.cratespro_url

  enable_apps     = var.enable_apps
  image_repo_base = var.image_repo_base
  image_tag       = var.image_tag
  app_images      = var.app_images
  app_resources   = var.app_resources

  db_url    = var.db_url
  redis_url = var.redis_url
  mysql_url = var.mysql_url

  enable_mega_init = var.enable_mega_init
  mega_init_image  = var.mega_init_image
  mega_init_args   = var.mega_init_args

  storage_class  = var.storage_class
  image_registry = var.image_registry

  enable_rustfs                 = var.enable_rustfs
  rustfs_access_key             = var.rustfs_access_key
  rustfs_secret_key             = var.rustfs_secret_key
  rustfs_bucket                 = var.rustfs_bucket
  rustfs_region                 = var.rustfs_region
  rustfs_storage_size           = var.rustfs_storage_size
  enable_rustfs_console_ingress = var.enable_rustfs_console_ingress
  rustfs_console_subdomain      = var.rustfs_console_subdomain
  rustfs_resources              = var.rustfs_resources

  enable_postgresql = var.enable_postgresql
  pg_username       = var.pg_username
  pg_password       = var.pg_password
  pg_database       = var.pg_database
  pg_storage_size   = var.pg_storage_size
  pg_resources      = var.pg_resources

  enable_mysql        = var.enable_mysql
  mysql_root_password = var.mysql_root_password
  mysql_username      = var.mysql_username
  mysql_password      = var.mysql_password
  mysql_database      = var.mysql_database
  mysql_storage_size  = var.mysql_storage_size
  mysql_resources     = var.mysql_resources

  enable_redis       = var.enable_redis
  redis_password     = var.redis_password
  redis_storage_size = var.redis_storage_size
  redis_resources    = var.redis_resources

  s3_access_key = var.s3_access_key
  s3_secret_key = var.s3_secret_key
  s3_bucket     = var.s3_bucket
  s3_region     = var.s3_region
  s3_endpoint   = var.s3_endpoint

  rails_env        = var.rails_env
  rails_master_key = var.rails_master_key
}
