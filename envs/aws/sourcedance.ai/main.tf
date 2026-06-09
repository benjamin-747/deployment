locals {
  portal_host    = "internship.${var.base_domain}"
  bot_host       = "webhooks.${var.base_domain}"
  docs_host      = "docs.${var.base_domain}"
  score_api_host = "api.${var.base_domain}"


  ecs_fargate = merge(
    {
      internship-portal    = { cpu = "512", memory = "1024" }
      internship-docs      = { cpu = "256", memory = "512" }
      internship-bot       = { cpu = "256", memory = "512" }
      internship-score-api = { cpu = "256", memory = "512" }
    },
    var.ecs_fargate_tasks
  )

  # Listener rule priority = slot * 100 + priority_env_offset.
  # priority_env_offset distinguishes envs sharing the same listener (0=default, 1=gitmono, 2=internship).
  priority_env_offset = 2

  # Per-service config driving the single for_each ECS module below.
  services = {
    internship-portal = {
      image             = "public.ecr.aws/m8q5m4u3/opensource-internship/portal:latest"
      port              = 7001
      host              = local.portal_host
      slot              = 1
      health_check_path = "/api/health"
      environment = [
        { "name" : "ATOMGIT_CLIENT_ID", "value" : "${var.atomgit_client_id}" },
        { "name" : "ATOMGIT_CLIENT_SECRET", "value" : "${var.atomgit_client_secret}" },
        { "name" : "APP_BASE_URL", "value" : "https://${local.portal_host}" },
        { "name" : "BETTER_AUTH_SECRET", "value" : "${var.better_auth_secret}" },
        { "name" : "BETTER_AUTH_URL", "value" : "https://${local.portal_host}" },
        { "name" : "INTERNAL_API_BASE_URL", "value" : "https://${local.portal_host}" },
        { "name" : "STORAGE_PROVIDER", "value" : "s3" },
        { "name" : "S3_REGION", "value" : "${var.region}" },
        { "name" : "S3_ACCESS_KEY_ID", "value" : "${var.s3_key}" },
        { "name" : "S3_ACCESS_KEY_SECRET", "value" : "${var.s3_secret_key}" },
        { "name" : "S3_BUCKET", "value" : "${var.s3_bucket}" },
        { "name" : "DATABASE_URL", "value" : "postgres://${var.db_username}:${var.db_password}@gitmega.c3aqu4m6k57p.ap-southeast-2.rds.amazonaws.com/${var.db_schema}?sslmode=require&uselibpqcompat=true" },
        { "name" : "GITHUB_CLIENT_ID", "value" : "${var.github_client_id}" },
        { "name" : "GITHUB_CLIENT_SECRET", "value" : "${var.github_client_secret}" },
        { "name" : "S3_ENDPOINT", "value" : "${var.s3_endpoint}" },
        { "name" : "NODE_OPTIONS", "value" : "--dns-result-order=ipv4first" },
        { "name" : "OPENSOURCE_INTEGRATION_TOKEN", "value" : "${var.opensource_integration_token}" },
        { "name" : "EMAIL_ENABLED", "value" : "${var.email_enabled}" },
        { "name" : "EMAIL_PROVIDER", "value" : "zepto" },
        { "name" : "ZEPTO_API_KEY", "value" : "${var.zepto_api_key}" },
        { "name" : "EMAIL_DEFAULT_FROM", "value" : "${var.email_default_from}" },
        { "name" : "S3_FORCE_PATH_STYLE", "value" : "${var.s3_force_path_style}" },
      ]
    }

    internship-docs = {
      image             = "public.ecr.aws/m8q5m4u3/opensource-internship/docs:latest"
      port              = 80
      host              = local.docs_host
      slot              = 2
      health_check_path = "/"
      environment       = []
    }

    internship-bot = {
      image             = "public.ecr.aws/m8q5m4u3/opensource-internship/bot:latest"
      port              = 3000
      host              = local.bot_host
      slot              = 3
      health_check_path = "/healthz"
      environment = [
        { "name" : "APP_ID", "value" : "${var.bot_app_id}" },
        { "name" : "PRIVATE_KEY", "value" : "${var.bot_private_key}" },
        { "name" : "WEBHOOK_SECRET", "value" : "${var.bot_webhook_secret}" },
        { "name" : "GITHUB_CLIENT_ID", "value" : "${var.bot_github_client_id}" },
        { "name" : "GITHUB_CLIENT_SECRET", "value" : "${var.bot_github_client_secret}" },
        { "name" : "API_ENDPOINT", "value" : "https://${local.score_api_host}/api/v1" },
        { "name" : "ATOMGIT_API_BASE", "value" : "https://api.atomgit.com/api/v5" },
        { "name" : "ATOMGIT_TOKEN", "value" : "${var.bot_atomgit_token}" },
        { "name" : "HOST", "value" : "0.0.0.0" },
        { "name" : "PORT", "value" : "3000" },
        { "name" : "PORTAL_ENDPOINT", "value" : "https://${local.portal_host}" },
        { "name" : "OPENSOURCE_INTEGRATION_TOKEN", "value" : "${var.opensource_integration_token}" },
        { "name" : "INTERNSHIP_PORTAL_URL", "value" : "https://${local.portal_host}" },
      ]
    }

    internship-score-api = {
      image             = "public.ecr.aws/m8q5m4u3/opensource-internship/api:latest"
      port              = 8080
      host              = local.score_api_host
      slot              = 4
      health_check_path = "/api/v1/healthz"
      environment = [
        { "name" : "HOST", "value" : "0.0.0.0" },
        { "name" : "PORT", "value" : "8080" },
        { "name" : "ZEPTO_AK", "value" : "${var.zepto_ak}" },
        { "name" : "ZEPTO_SK", "value" : "${var.zepto_sk}" },
        { "name" : "SEND_EMAIL", "value" : "${var.send_email}" },
        { "name" : "DATABASE_URL", "value" : "postgres://${var.db_username}:${var.db_password}@gitmega.c3aqu4m6k57p.ap-southeast-2.rds.amazonaws.com/${var.db_schema}?sslmode=require" },
        { "name" : "TEMPLATE_DIR", "value" : "/opt/r2cn" },
        { "name" : "EMAIL_FROM", "value" : "${var.email_default_from}" }
      ]
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.default_tags
  }
}

module "acm" {
  source      = "../../../modules/security/aws/acm"
  domain_name = "*.${var.base_domain}"
}

module "alb" {
  source = "../../../modules/compute/aws/alb"
  name   = "${var.app_suffix}-shared-alb"
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
  security_group_ids          = [var.ecs_sg]
  target_groups = {
    for name, svc in local.services : name => {
      name              = name
      port              = svc.port
      health_check_path = svc.health_check_path
    }
  }
}


module "service" {
  for_each = local.services

  source          = "../../../modules/compute/aws/ecs"
  region          = var.region
  cluster_name    = "internship-app"
  task_family     = "${var.app_suffix}-${trimprefix(each.key, "internship-")}"
  container_name  = "app"
  container_image = each.value.image
  container_port  = each.value.port
  service_name    = each.key
  cpu             = local.ecs_fargate[each.key].cpu
  memory          = local.ecs_fargate[each.key].memory
  subnet_ids      = var.public_subnet_ids

  security_group_ids = [var.ecs_sg]
  environment        = each.value.environment

  load_balancers = [{
    target_group_arn = module.alb.target_group_arns[each.key]
    container_name   = "app"
    container_port   = each.value.port
    host_headers     = [each.value.host]
    priority         = each.value.slot * 100 + local.priority_env_offset
  }]
  alb_listener_arn = module.alb.https_listener_arn
}
