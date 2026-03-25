locals {
  mono_host          = "git.${var.base_domain}"
  ui_host            = "app.${var.base_domain}"
  orion_host         = "orion.${var.base_domain}"
  campsite_host      = "api.${var.base_domain}"
  campsite_auth_host = "auth.${var.base_domain}"
  note_sync_host     = "sync.${var.base_domain}"

  ecs_fargate = merge(
    {
      mono_engine   = { cpu = "512", memory = "1024" }
      mega_ui       = { cpu = "256", memory = "512" }
      mega_web_sync = { cpu = "256", memory = "512" }
      orion_server  = { cpu = "256", memory = "512" }
      campsite_api  = { cpu = "512", memory = "1024" }
    },
    var.ecs_fargate_tasks
  )
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

module "gitmono_orion" {
  source = "../../../../modules/compute/aws/ec2"

  name          = "gitmono-orion"
  ami           = var.ec2_ami
  instance_type = var.ec2_instance_type
  vpc_id        = var.vpc_id
  subnet_ids    = var.public_subnet_ids
}

resource "aws_eip" "gitmono_orion" {
  domain = "vpc"
  tags = {
    Name = "${var.app_suffix}-gitmono-orion"
  }
}

resource "aws_eip_association" "gitmono_orion" {
  allocation_id = aws_eip.gitmono_orion.id
  instance_id   = module.gitmono_orion.instance_id
}


module "gitmega_orion" {
  source = "../../../../modules/compute/aws/ec2"

  # Unique AWS resource names inside this env
  name          = "gitmega-orion"
  ami           = var.ec2_ami
  instance_type = var.ec2_instance_type

  vpc_id     = var.vpc_id
  subnet_ids = var.public_subnet_ids
}

resource "aws_eip" "gitmega_orion" {
  domain = "vpc"
  tags = {
    Name = "${var.app_suffix}-gitmega-orion"
  }
}

resource "aws_eip_association" "gitmega_orion" {
  allocation_id = aws_eip.gitmega_orion.id
  instance_id   = module.gitmega_orion.instance_id
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
  container_image = "public.ecr.aws/m8q5m4u3/mega/mono-engine:latest"
  container_port  = 8000
  service_name    = "mono-engine"
  cpu             = local.ecs_fargate["mono_engine"].cpu
  memory          = local.ecs_fargate["mono_engine"].memory
  subnet_ids      = var.public_subnet_ids

  security_group_ids = [module.sg.sg_id]
  environment = [
    {
      "name" : "MEGA_LOG__LEVEL",
      "value" : "info"
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
      "name" : "MEGA_DATABASE__DB_URL",
      "value" : "postgres://${var.db_username}:${var.db_password}@gitmega.c3aqu4m6k57p.ap-southeast-2.rds.amazonaws.com/${var.db_schema}?sslmode=require"
    },
    {
      "name" : "MEGA_MONOREPO__STORAGE_TYPE",
      "value" : "s3"
    },
    {
      "name" : "MEGA_BUILD__ORION_SERVER",
      "value" : "https://${local.orion_host}"
    },
    {
      "name" : "MEGA_LFS__STORAGE_TYPE",
      "value" : "s3"
    },
    {
      "name" : "MEGA_OBJECT_STORAGE__S3__ACCESS_KEY_ID",
      "value" : "${var.s3_key}"
    },
    {
      "name" : "MEGA_OBJECT_STORAGE__S3__SECRET_ACCESS_KEY",
      "value" : "${var.s3_secret_key}"
    },
    {
      "name" : "MEGA_OBJECT_STORAGE__S3__BUCKET",
      "value" : "${var.s3_bucket}"
    },
    {
      "name" : "MEGA_OBJECT_STORAGE__S3__REGION",
      "value" : "${var.region}"
    },
    {
      "name" : "MEGA_OAUTH__CAMPSITE_API_DOMAIN",
      "value" : "https://${local.campsite_host}"
    },
    {
      "name" : "MEGA_OAUTH__ALLOWED_CORS_ORIGINS",
      "value" : "https://${local.ui_host}"
    },
    {
      "name" : "MEGA_REDIS__URL",
      "value" : "rediss://${var.redis_endpoint}"
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
    }
  ]
}

module "mega-ui-app" {
  source          = "../../../../modules/compute/aws/ecs"
  region          = var.region
  cluster_name    = "${var.app_suffix}-mega-app"
  task_family     = "${var.app_suffix}-mega-ui"
  container_name  = "app"
  container_image = "public.ecr.aws/m8q5m4u3/mega/mega-ui:${var.ui_env}-latest"
  container_port  = 3000
  service_name    = "mega-ui-service"
  cpu             = local.ecs_fargate["mega_ui"].cpu
  memory          = local.ecs_fargate["mega_ui"].memory
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
  container_image = "public.ecr.aws/m8q5m4u3/mega/web-sync-server:latest"
  container_port  = 9000
  service_name    = "mega-web-sync-service"
  cpu             = local.ecs_fargate["mega_web_sync"].cpu
  memory          = local.ecs_fargate["mega_web_sync"].memory
  subnet_ids      = var.public_subnet_ids
  desired_count   = 1

  security_group_ids = [module.sg.sg_id]
  environment = [
    {
      "name" : "API_URL",
      "value" : "https://api.gitmono.com"
    },
    {
      "name" : "NODE_ENV",
      "value" : "production"
    },
  ]
  load_balancers = [{
    target_group_arn = module.alb.target_group_arns["sync_server"]
    container_name   = "app"
    container_port   = 9000
    host_headers     = ["${local.note_sync_host}"]
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
  container_image = "public.ecr.aws/m8q5m4u3/mega/orion-server:latest"
  container_port  = 8004
  service_name    = "orion-server-service"
  cpu             = local.ecs_fargate["orion_server"].cpu
  memory          = local.ecs_fargate["orion_server"].memory
  subnet_ids      = var.public_subnet_ids

  security_group_ids = [module.sg.sg_id]
  environment = [
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
    {
      "name" : "MEGA_OAUTH__ALLOWED_CORS_ORIGINS",
      "value" : "https://${local.ui_host}"
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
}


module "campsite-api-app" {
  source          = "../../../../modules/compute/aws/ecs"
  region          = var.region
  cluster_name    = "${var.app_suffix}-mega-app"
  task_family     = "${var.app_suffix}-campsite-api"
  container_name  = "app"
  container_image = "public.ecr.aws/m8q5m4u3/mega/campsite-api:latest"
  container_port  = 8080
  service_name    = "campsite-api-service"
  cpu             = local.ecs_fargate["campsite_api"].cpu
  memory          = local.ecs_fargate["campsite_api"].memory
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

output "gitmono_orion_instance_id" {
  value = module.gitmono_orion.instance_id
}

output "gitmono_orion_public_ip" {
  value = aws_eip.gitmono_orion.public_ip
}

output "gitmega_orion_instance_id" {
  value = module.gitmega_orion.instance_id
}

output "gitmega_orion_public_ip" {
  value = aws_eip.gitmega_orion.public_ip
}
