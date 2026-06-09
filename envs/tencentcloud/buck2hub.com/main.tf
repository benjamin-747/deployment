locals {
  mono_host          = "git.${var.base_domain}"
  ui_host            = "app.${var.base_domain}"
  orion_host         = "orion.${var.base_domain}"
  campsite_host      = "api.${var.base_domain}"
  campsite_auth_host = "auth.${var.base_domain}"
  note_sync_host     = "sync.${var.base_domain}"

  ssl_domain = coalesce(var.ssl_domain, "*.${var.base_domain}")

  ssl_certificate_pem = var.ssl_create_mode == "upload" ? coalesce(
    var.ssl_certificate_pem,
    var.ssl_certificate_pem_file != "" ? file(var.ssl_certificate_pem_file) : null
  ) : var.ssl_certificate_pem

  ssl_private_key_pem = var.ssl_create_mode == "upload" ? coalesce(
    var.ssl_private_key_pem,
    var.ssl_private_key_pem_file != "" ? file(var.ssl_private_key_pem_file) : null
  ) : var.ssl_private_key_pem

  tags = merge(
    {
      Environment = var.base_domain
      ManagedBy   = "terraform"
    },
    var.default_tags
  )

  # Passwords are URL-encoded; special chars like '#' otherwise break URL parsing
  # (e.g. '#' is treated as a fragment delimiter and truncates the connection string).
  db_url    = "postgres://${var.db_username}:${urlencode(var.db_password)}@${module.postgresql.endpoint}/${var.db_schema}"
  redis_url = "redis://:${urlencode(var.redis_password)}@${module.redis.endpoint}"

  # COS S3-compatible endpoint must use virtual-hosted style
  # (bucket.cos.<region>.myqcloud.com); path-style cos.<region>.myqcloud.com/bucket returns 403.
  cos_endpoint = module.cos.bucket_url

  # Per-service compute resources. Defaults below; override any service via the
  # workload_resources variable (terraform.tfvars).
  workload_resources_default = {
    mono_engine   = { cpu = "500m", memory = "1024Mi", replicas = 1 }
    mega_ui       = { cpu = "250m", memory = "512Mi", replicas = 1 }
    mega_web_sync = { cpu = "250m", memory = "512Mi", replicas = 1 }
    orion_server  = { cpu = "250m", memory = "512Mi", replicas = 1 }
    campsite_api  = { cpu = "500m", memory = "1024Mi", replicas = 1 }
  }
  wres = merge(local.workload_resources_default, var.workload_resources)

  # Backend services (EKSCI). Port and health check per compute target.
  backend_services = {
    mono_engine   = { port = 8000, health_check_path = "/" }
    mega_ui       = { port = 3000, health_check_path = "/" }
    mega_web_sync = { port = 9000, health_check_path = "/" }
    orion_server  = { port = 8004, health_check_path = "/" }
    campsite_api  = { port = 8080, health_check_path = "/" }
  }

  # CLB host rules; multiple hostnames may share one backend (e.g. api + auth -> campsite_api).
  clb_host_rules = {
    mono_engine   = { host = local.mono_host, backend = "mono_engine" }
    mega_ui       = { host = local.ui_host, backend = "mega_ui" }
    mega_web_sync = { host = local.note_sync_host, backend = "mega_web_sync" }
    orion_server  = { host = local.orion_host, backend = "orion_server" }
    campsite_api  = { host = local.campsite_host, backend = "campsite_api" }
    campsite_auth = { host = local.campsite_auth_host, backend = "campsite_api" }
  }

  # gitmono service set mirrors the AWS gitmono.com ECS stack, retargeted to the
  # Tencent Cloud PostgreSQL / Redis / COS endpoints created above. Consumed by eksci.tf.
  workloads_all = {
    mono_engine = {
      image          = "${var.image_repo_base}/mono-engine:latest"
      container_port = 8000
      cpu            = local.wres["mono_engine"].cpu
      memory         = local.wres["mono_engine"].memory
      replicas       = local.wres["mono_engine"].replicas
      service_type   = "ClusterIP"
      environment = [
        { name = "MEGA_LOG__LEVEL", value = "info" },
        { name = "MEGA_LOG__WITH_ANSI", value = "false" },
        { name = "MEGA_AUTHENTICATION__ENABLE_HTTP_PUSH", value = "true" },
        { name = "MEGA_BUILD__ENABLE_BUILD", value = "true" },
        # Tencent Cloud PostgreSQL has SSL disabled by default; intra-VPC traffic so disable TLS.
        { name = "MEGA_DATABASE__DB_URL", value = "${local.db_url}?sslmode=disable" },
        { name = "MEGA_OBJECT_STORAGE__STORAGE_TYPE", value = "s3compatible" },
        { name = "MEGA_BUILD__ORION_SERVER", value = "https://${local.orion_host}" },
        { name = "MEGA_OBJECT_STORAGE__S3__ACCESS_KEY_ID", value = var.tencentcloud_secret_id },
        { name = "MEGA_OBJECT_STORAGE__S3__SECRET_ACCESS_KEY", value = var.tencentcloud_secret_key },
        { name = "MEGA_OBJECT_STORAGE__S3__BUCKET", value = module.cos.bucket_name },
        { name = "MEGA_OBJECT_STORAGE__S3__REGION", value = var.region },
        { name = "MEGA_OBJECT_STORAGE__S3__ENDPOINT_URL", value = local.cos_endpoint },
        { name = "MEGA_OAUTH__CAMPSITE_API_DOMAIN", value = "https://${local.campsite_host}" },
        { name = "MEGA_OAUTH__ALLOWED_CORS_ORIGINS", value = "https://${local.ui_host}" },
        { name = "MEGA_REDIS__URL", value = local.redis_url },
      ]
    }
    mega_ui = {
      image          = "${var.image_repo_base}/mega-ui:${var.ui_env}-latest"
      container_port = 3000
      cpu            = local.wres["mega_ui"].cpu
      memory         = local.wres["mega_ui"].memory
      replicas       = local.wres["mega_ui"].replicas
      service_type   = "ClusterIP"
      environment    = []
    }
    mega_web_sync = {
      image          = "${var.image_repo_base}/web-sync-server:latest"
      container_port = 9000
      cpu            = local.wres["mega_web_sync"].cpu
      memory         = local.wres["mega_web_sync"].memory
      replicas       = local.wres["mega_web_sync"].replicas
      service_type   = "ClusterIP"
      environment = [
        { name = "API_URL", value = "https://${local.campsite_host}" },
        { name = "NODE_ENV", value = "production" },
      ]
    }
    orion_server = {
      image          = "${var.image_repo_base}/orion-server:latest"
      container_port = 8004
      cpu            = local.wres["orion_server"].cpu
      memory         = local.wres["orion_server"].memory
      replicas       = local.wres["orion_server"].replicas
      service_type   = "ClusterIP"
      environment = [
        { name = "MEGA_OBJECT_STORAGE__S3__ACCESS_KEY_ID", value = var.tencentcloud_secret_id },
        { name = "MEGA_OBJECT_STORAGE__S3__SECRET_ACCESS_KEY", value = var.tencentcloud_secret_key },
        { name = "MEGA_OBJECT_STORAGE__S3__BUCKET", value = module.cos.bucket_name },
        { name = "MEGA_OBJECT_STORAGE__S3__REGION", value = var.region },
        { name = "MEGA_OBJECT_STORAGE__S3__ENDPOINT_URL", value = local.cos_endpoint },
        { name = "MEGA_ORION_SERVER__DB_URL", value = local.db_url },
        { name = "MEGA_ORION_SERVER__MONOBASE_URL", value = "https://${local.mono_host}" },
        { name = "MEGA_OBJECT_STORAGE__STORAGE_TYPE", value = "s3compatible" },
        { name = "MEGA_OAUTH__ALLOWED_CORS_ORIGINS", value = "https://${local.ui_host}" },
      ]
    }
    campsite_api = {
      image          = "${var.image_repo_base}/campsite-api:latest"
      container_port = 8080
      cpu            = local.wres["campsite_api"].cpu
      memory         = local.wres["campsite_api"].memory
      replicas       = local.wres["campsite_api"].replicas
      service_type   = "ClusterIP"
      environment = [
        { name = "DEV_APP_URL", value = "http://${local.ui_host}" },
        { name = "PORT", value = "8080" },
        { name = "RAILS_ENV", value = var.rails_env },
        { name = "RAILS_MASTER_KEY", value = var.rails_master_key },
        { name = "SERVER_COMMAND", value = "bundle exec puma" },
      ]
    }
  }
}

# ---------------------------------------------------------------------------
# Deployment order:
#   1. network   -> VPC + subnets                    (implemented)
#   2. security  -> security groups + SSL cert       (implemented)
#   3. storage   -> PostgreSQL + COS + Redis          (implemented)
#   4. compute   -> EKSCI container instances (eksci.tf)
#   5. clb       -> CLB listeners + forwarding rules  (implemented)
# ---------------------------------------------------------------------------

# 1. Network
module "vpc" {
  source = "../../../modules/network/tencentcloud/vpc"

  name                = "${var.app_suffix}-vpc"
  region              = var.region
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  tags                = local.tags
}

# 2. Security
module "security_group" {
  source = "../../../modules/security/tencentcloud/security_group"

  name   = "${var.app_suffix}-sg"
  vpc_id = module.vpc.vpc_id
  tags   = local.tags

  # 80/443 public (CLB); 5432/6379 only from inside the VPC so EKSCI instances
  # can reach PostgreSQL and Redis (which share this security group).
  ingress_rules = [
    {
      action      = "ACCEPT"
      protocol    = "TCP"
      port        = "80"
      cidr_block  = "0.0.0.0/0"
      description = "HTTP"
    },
    {
      action      = "ACCEPT"
      protocol    = "TCP"
      port        = "443"
      cidr_block  = "0.0.0.0/0"
      description = "HTTPS"
    },
    {
      action      = "ACCEPT"
      protocol    = "TCP"
      port        = "5432"
      cidr_block  = var.vpc_cidr
      description = "PostgreSQL (intra-VPC)"
    },
    {
      action      = "ACCEPT"
      protocol    = "TCP"
      port        = "6379"
      cidr_block  = var.vpc_cidr
      description = "Redis (intra-VPC)"
    },
    # CLB health checks originate from 100.64.0.0/10 (or CLB VIP), not only VPC CIDR.
    # L7 CLB also forwards client IPs to backends — 0.0.0.0/0 on app ports is required
    # unless CLB security-group passthrough is enabled.
    {
      action      = "ACCEPT"
      protocol    = "TCP"
      port        = "3000"
      cidr_block  = "0.0.0.0/0"
      description = "mega-ui via CLB"
    },
    {
      action      = "ACCEPT"
      protocol    = "TCP"
      port        = "8000"
      cidr_block  = "0.0.0.0/0"
      description = "mono-engine via CLB"
    },
    {
      action      = "ACCEPT"
      protocol    = "TCP"
      port        = "8004"
      cidr_block  = "0.0.0.0/0"
      description = "orion-server via CLB"
    },
    {
      action      = "ACCEPT"
      protocol    = "TCP"
      port        = "8080"
      cidr_block  = "0.0.0.0/0"
      description = "campsite-api via CLB"
    },
    {
      action      = "ACCEPT"
      protocol    = "TCP"
      port        = "9000"
      cidr_block  = "0.0.0.0/0"
      description = "mega-web-sync via CLB"
    },
  ]
}

module "ssl_certificate" {
  source = "../../../modules/security/tencentcloud/ssl_certificate"

  domain_name     = local.ssl_domain
  create_mode     = var.ssl_create_mode
  certificate_id  = var.ssl_certificate_id
  certificate_pem = local.ssl_certificate_pem
  private_key_pem = local.ssl_private_key_pem
  dv_auth_method  = var.ssl_dv_auth_method
  contact_email   = var.ssl_contact_email
  contact_phone   = var.ssl_contact_phone
  auto_complete   = var.ssl_auto_complete
  tags            = local.tags
}

# 3. Storage
module "postgresql" {
  source = "../../../modules/storage/tencentcloud/postgresql"

  name               = "${var.app_suffix}-pg"
  region             = var.region
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security_group.security_group_id]
  db_username        = var.db_username
  db_password        = var.db_password
  db_schema          = var.db_schema
  cpu                = var.db_cpu
  memory             = var.db_memory
  storage            = var.db_storage
  tags               = local.tags
}

module "cos" {
  source = "../../../modules/storage/tencentcloud/cos"

  name   = var.cos_bucket
  region = var.region
  tags   = local.tags
}

module "redis" {
  source = "../../../modules/storage/tencentcloud/redis"

  name               = "${var.app_suffix}-redis"
  region             = var.region
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security_group.security_group_id]
  password           = var.redis_password
  memory_size        = var.redis_mem_size
  type_id            = var.redis_type_id
  tags               = local.tags
}

# 4. Compute: see eksci.tf (EKSCI container instances).

# 5. Load balancer (CLB)
module "clb" {
  source = "../../../modules/compute/tencentcloud/clb"

  name               = "${var.app_suffix}-clb"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security_group.security_group_id]
  enable_https       = var.ssl_create_mode != "disabled"
  certificate_id     = module.ssl_certificate.certificate_id

  # Scheme B: one public CLB, host-based routing (multiple hosts may share a backend).
  target_groups = {
    for name, rule in local.clb_host_rules : name => {
      domain            = rule.host
      url               = "/"
      health_check_path = local.backend_services[rule.backend].health_check_path
      port              = local.backend_services[rule.backend].port
    }
  }

  tags = local.tags
}
