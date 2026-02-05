locals {
  mono_host          = "git.${var.base_domain}"
  ui_host            = "app.${var.base_domain}"
  orion_host         = "orion.${var.base_domain}"
  campsite_host      = "api.${var.base_domain}"
  campsite_auth_host = "auth.${var.base_domain}"
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source              = "../../../../modules/network/aws/vpc"
  vpc_cidr            = "10.0.0.0/16"
  region              = var.region
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  name                = "mega-vpc"
}

module "sg" {
  source = "../../../../modules/security/aws/security_group"

  vpc_id = module.vpc.vpc_id
}

module "efs" {
  source     = "../../../../modules/storage/aws/efs"
  name       = "${var.app_suffix}-mono-efs"
  vpc_id     = module.vpc.vpc_id
  vpc_cidr   = "10.0.0.0/16"
  subnet_ids = module.vpc.public_subnet_ids
}


module "acm" {
  source      = "../../../../modules/security/aws/acm"
  domain_name = "*.${var.base_domain}"
}

module "alb" {
  source              = "../../../../modules/compute/aws/alb"
  name                = "${var.app_suffix}-mega-alb"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnet_ids
  acm_certificate_arn = module.acm.certificate_arn
  security_group_ids  = [module.sg.sg_id]
  target_groups = {
    mega_ui = {
      name              = "mega-ui"
      port              = 3000
      health_check_path = "/api/health"
    }
    campsite_api = {
      name              = "campsite-api"
      port              = 8080
      health_check_path = "/health"
    }
    mono_engine = {
      name              = "mono-engine"
      port              = 8000
      health_check_path = "/api/v1/status"
    }
    sync_server = {
      name              = "sync-server"
      port              = 9000
      health_check_path = "/"
    }
    orion_server = {
      name              = "orion-server"
      port              = 8004
      health_check_path = "/"
    }
  }
}


module "mono-engine" {
  source          = "../../../../modules/compute/aws/ecs"
  region          = var.region
  cluster_name    = "${var.app_suffix}-mega-app"
  task_family     = "${var.app_suffix}-mono-engine"
  container_name  = "app"
  container_image = "public.ecr.aws/m8q5m4u3/mega:mono-0.1.0-pre-release"
  container_port  = 8000
  service_name    = "mono-engine"
  cpu             = "512"
  memory          = "1024"
  subnet_ids      = module.vpc.public_subnet_ids

  security_group_ids = [module.sg.sg_id]
  environment = [
    {
      "name" : "MEGA_ALLOWED_CORS_ORIGINS",
      "value" : "http://local.${var.base_domain}, https://${local.ui_host}, http://app.gitmono.test"
    },
    {
      "name" : "MEGA_AUTHENTICATION__ENABLE_HTTP_PUSH",
      "value" : "true"
    },
    {
      "name" : "MEGA_BUILD__ENABLE_BUILD",
      "value" : "true"
    },
    {
      "name" : "MEGA_DATABASE__ACQUIRE_TIMEOUT",
      "value" : "3"
    },
    {
      "name" : "MEGA_DATABASE__CONNECT_TIMEOUT",
      "value" : "3"
    },
    {
      "name" : "MEGA_DATABASE__DB_URL",
      "value" : "postgres://${var.db_username}:${var.db_password}@${module.rds_pg.db_endpoint}/${var.db_schema}?sslmode=require"
    },
    {
      "name" : "MEGA_LFS__STORAGE_TYPE",
      "value" : "s3"
    },
    {
      "name" : "MEGA_LOG__LEVEL",
      "value" : "info"
    },
    {
      "name" : "MEGA_MONOREPO__STORAGE_TYPE",
      "value" : "s3"
    },
    {
      "name" : "MEGA_REDIS__URL",
      "value" : "rediss://${module.valkey.endpoint[0].address}:${module.valkey.endpoint[0].port}"
    },
    {
      "name" : "MEGA_S3__ACCESS_KEY_ID",
      "value" : "${var.s3_key}"
    },
    {
      "name" : "MEGA_S3__BUCKET",
      "value" : "${var.s3_bucket}"
    },
    {
      "name" : "MEGA_S3__ENDPOINT_URL",
      "value" : ""
    },
    {
      "name" : "MEGA_S3__REGION",
      "value" : "${var.region}"
    },
    {
      "name" : "MEGA_S3__SECRET_ACCESS_KEY",
      "value" : "${var.s3_secret_key}"
    },
  ]

  load_balancers = [{
    target_group_arn = module.alb.target_group_arns["mono_engine"]
    container_name   = "app"
    container_port   = 8000
    host_headers     = ["${local.mono_host}"]
    priority         = 100
  }]
  alb_listener_arn = module.alb.https_listener_arn

  efs_volume = {
    name           = "volumn1"
    file_system_id = module.efs.file_system_id
    root_directory = "/"
  }
  mount_points = [
    {
      containerPath = "/opt/mega/vault"
      readOnly      = false
      sourceVolume  = "volumn1"
    },
    {
      containerPath = "/opt/mega/etc"
      readOnly      = false
      sourceVolume  = "volumn1"
    }
  ]
}

module "mega-ui-app" {
  source          = "../../../../modules/compute/aws/ecs"
  region          = var.region
  cluster_name    = "${var.app_suffix}-mega-app"
  task_family     = "${var.app_suffix}-mega-ui"
  container_name  = "app"
  container_image = "public.ecr.aws/m8q5m4u3/mega:mega-ui-${var.ui_env}-0.1.0-pre-release"
  container_port  = 3000
  service_name    = "mega-ui-service"
  cpu             = "512"
  memory          = "1024"
  subnet_ids      = module.vpc.public_subnet_ids

  security_group_ids = [module.sg.sg_id]
  environment        = []
  load_balancers = [{
    target_group_arn = module.alb.target_group_arns["mega_ui"]
    container_name   = "app"
    container_port   = 3000
    host_headers     = ["${local.ui_host}"]
    priority         = 200
  }]
  alb_listener_arn = module.alb.https_listener_arn
}

module "mega-web-sync-app" {
  source          = "../../../../modules/compute/aws/ecs"
  region          = var.region
  cluster_name    = "${var.app_suffix}-mega-app"
  task_family     = "${var.app_suffix}-mega-web-sync"
  container_name  = "app"
  container_image = "public.ecr.aws/m8q5m4u3/mega:mega-web-sync-server-0.1.0-pre-release"
  container_port  = 9000
  service_name    = "mega-web-sync-service"
  cpu             = "256"
  memory          = "512"
  subnet_ids      = module.vpc.public_subnet_ids

  security_group_ids = [module.sg.sg_id]
  environment = [
    {
      "name" : "APP_ENV",
      "value" : "development"
    },
    {
      "name" : "NEXT_PUBLIC_SYNC_URL",
      "value" : "ws://sync.${var.base_domain}"
    },
  ]
  load_balancers = [{
    target_group_arn = module.alb.target_group_arns["sync_server"]
    container_name   = "app"
    container_port   = 9000
    host_headers     = ["sync.${var.base_domain}"]
    priority         = 300
  }]
  alb_listener_arn = module.alb.https_listener_arn
}


module "orion-server-app" {
  source          = "../../../../modules/compute/aws/ecs"
  region          = var.region
  cluster_name    = "${var.app_suffix}-mega-app"
  task_family     = "${var.app_suffix}-orion-server"
  container_name  = "app"
  container_image = "public.ecr.aws/m8q5m4u3/mega:orion-server-0.1.0-pre-release"
  container_port  = 8004
  service_name    = "orion-server-service"
  cpu             = "256"
  memory          = "512"
  subnet_ids      = module.vpc.public_subnet_ids

  security_group_ids = [module.sg.sg_id]
  environment = [
    {
      "name" : "ALLOWED_CORS_ORIGINS",
      "value" : "http://local.${var.base_domain}, https://${local.ui_host}, http://app.gitmono.test"
    },
    {
      "name" : "AWS_ACCESS_KEY_ID",
      "value" : "${var.s3_key}"
    },
    {
      "name" : "AWS_DEFAULT_REGION",
      "value" : "${var.region}"
    },
    {
      "name" : "AWS_SECRET_ACCESS_KEY",
      "value" : "${var.s3_secret_key}"
    },
    {
      "name" : "BUCKET_NAME",
      "value" : "${var.s3_bucket}"
    },
    {
      "name" : "BUILD_LOG_DIR",
      "value" : "/tmp/megadir/buck2ctl"
    },
    {
      "name" : "DATABASE_URL",
      "value" : "postgres://${var.db_username}:${var.db_password}@${module.rds_pg.db_endpoint}/${var.db_schema}"
    },
    {
      "name" : "LOG_STREAM_BUFFER",
      "value" : "4096"
    },
    {
      "name" : "LOGGER_STORAGE_TYPE",
      "value" : "s3"
    },
    {
      "name" : "MONOBASE_URL",
      "value" : "https://${local.mono_host}"
    },
    {
      "name" : "PORT",
      "value" : "8004"
    },
  ]
  load_balancers = [{
    target_group_arn = module.alb.target_group_arns["orion_server"]
    container_name   = "app"
    container_port   = 8004
    host_headers     = ["${local.orion_host}"]
    priority         = 400
  }]
  alb_listener_arn = module.alb.https_listener_arn
}


module "campsite-api-app" {
  source          = "../../../../modules/compute/aws/ecs"
  region          = var.region
  cluster_name    = "${var.app_suffix}-mega-app"
  task_family     = "${var.app_suffix}-campsite-api"
  container_name  = "app"
  container_image = "public.ecr.aws/m8q5m4u3/mega:campsite-0.1.0-pre-release"
  container_port  = 8080
  service_name    = "campsite-api-service"
  cpu             = "512"
  memory          = "1024"
  subnet_ids      = module.vpc.public_subnet_ids

  security_group_ids = [module.sg.sg_id]
  environment = [
    {
      "name" : "DEV_APP_URL",
      "value" : "http://${local.ui_host}"
    },
    {
      "name" : "PORT",
      "value" : "8080"
    },
    {
      "name" : "RAILS_ENV",
      "value" : "${var.rails_env}"
    },
    {
      "name" : "RAILS_MASTER_KEY",
      "value" : "${var.rails_master_key}"
    },
    {
      "name" : "SERVER_COMMAND",
      "value" : "bundle exec puma"
    }
  ]
  load_balancers = [{
    target_group_arn = module.alb.target_group_arns["campsite_api"]
    container_name   = "app"
    container_port   = 8080
    host_headers     = ["${local.campsite_host}", "${local.campsite_auth_host}"]
    priority         = 500
  }]
  alb_listener_arn = module.alb.https_listener_arn

}


module "rds_pg" {
  source              = "../../../../modules/storage/aws/rds"
  engine              = "postgres"
  engine_version      = "17"
  identifier          = "mega-postgres-tf"
  instance_class      = "db.t4g.micro"
  allocated_storage   = 20
  storage_type        = "gp2"
  username            = var.db_username
  password            = var.db_password
  db_name             = "mono"
  publicly_accessible = true
  subnet_ids          = module.vpc.public_subnet_ids
  security_group_ids  = [module.sg.sg_id]
}


# module "rds_mysql" {
#   source             = "../../../../modules/storage/aws/rds"
#   engine             = "mysql"
#   engine_version     = "8.0"
#   identifier         = "campsite-mysql"
#   instance_class     = "db.t4g.micro"
#   allocated_storage  = 20
#   storage_type       = "gp2"
#   username            = var.db_username
#   password            = var.db_password
#   db_name            = "demo_db"
#   publicly_accessible = true
#   subnet_ids         = [module.vpc.public_subnet_ids]
#   security_group_ids = [module.sg.sg_id]
# }

module "valkey" {
  source             = "../../../../modules/storage/aws/valkey"
  name               = "mega-valkey-tf"
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.sg.sg_id]
}


output "pg_endpoint" {
  value = module.rds_pg.db_endpoint
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "valkey_endpoint" {
  value = module.valkey.endpoint
}
