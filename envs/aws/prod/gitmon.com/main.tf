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

// alb 中需要手动添加新创建的这个sg
module "sg" {
  source = "../../../../modules/security/aws/security_group"
  vpc_id = var.vpc_id
}

module "efs" {
  source     = "../../../../modules/storage/aws/efs"
  name       = "${var.app_suffix}-mono-efs"
  vpc_id     = var.vpc_id
  vpc_cidr   = var.vpc_cidr
  subnet_ids = var.public_subnet_ids
}


module "acm" {
  source      = "../../../../modules/security/aws/acm"
  domain_name = "*.${var.base_domain}"
}


module "alb" {
  source = "../../../../modules/compute/aws/alb"
  name   = "${var.app_suffix}-mega-alb"
  tags = {
    Environment = var.base_domain
    ManagedBy   = "terraform"
  }
  vpc_id                      = var.vpc_id
  subnet_ids                  = var.public_subnet_ids
  existing_alb_arn            = var.existing_alb_arn
  existing_https_listener_arn = var.existing_https_listener_arn
  create_alb_sg               = false
  acm_certificate_arn         = module.acm.certificate_arn
  security_group_ids          = [module.sg.sg_id]
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
  subnet_ids      = var.public_subnet_ids

  security_group_ids = [module.sg.sg_id]
  environment = [
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
      "value" : "postgres://${var.db_username}:${var.db_password}@gitmega.c3aqu4m6k57p.ap-southeast-2.rds.amazonaws.com/${var.db_schema}?sslmode=require"
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
      "value" : "rediss://${var.redis_endpoint}"
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
    priority         = 101
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
  subnet_ids      = var.public_subnet_ids

  security_group_ids = [module.sg.sg_id]
  environment        = []
  load_balancers = [{
    target_group_arn = module.alb.target_group_arns["mega_ui"]
    container_name   = "app"
    container_port   = 3000
    host_headers     = ["${local.ui_host}"]
    priority         = 201
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
  subnet_ids      = var.public_subnet_ids
  desired_count   = 0

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
    priority         = 301
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
  subnet_ids      = var.public_subnet_ids

  security_group_ids = [module.sg.sg_id]
  environment = [
    {
      "name" : "MEGA_CONFIG",
      "value" : "/opt/mega/etc/config.toml"
    },
    {
      "name" : "MEGA_OBJECT_STORAGE__S3_BUCKET",
      "value" : "${var.s3_bucket}"
    },

    {
      "name" : "MEGA_OBJECT_STORAGE__S3_REGION",
      "value" : "${var.region}"
    },
    {
      "name" : "MEGA_ORION_SERVER__DB_URL",
      "value" : "postgres://${var.db_username}:${var.db_password}@gitmega.c3aqu4m6k57p.ap-southeast-2.rds.amazonaws.com/${var.db_schema}"
    },
    {
      "name" : "MEGA_ORION_SERVER__MONOBASE_URL",
      "value" : "https://${local.mono_host}"
    },
    {
      "name" : "MEGA_ORION_SERVER__STORAGE_TYPE",
      "value" : "s3"
    },
  ]
  load_balancers = [{
    target_group_arn = module.alb.target_group_arns["orion_server"]
    container_name   = "app"
    container_port   = 8004
    host_headers     = ["${local.orion_host}"]
    priority         = 401
  }]
  alb_listener_arn = module.alb.https_listener_arn

  efs_volume = {
    name           = "volumn1"
    file_system_id = module.efs.file_system_id
    root_directory = "/"
  }
  mount_points = [
    {
      containerPath = "/opt/mega/etc"
      readOnly      = false
      sourceVolume  = "volumn1"
    }
  ]
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
  subnet_ids      = var.public_subnet_ids

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
    priority         = 501
  }]
  alb_listener_arn = module.alb.https_listener_arn
}
