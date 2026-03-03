locals {
  distribution_host = "distribution.${var.base_domain}"
}

provider "aws" {
  region = var.region
}

module "acm" {
  source      = "../../../../modules/security/aws/acm"
  domain_name = "*.${var.base_domain}"
}


module "alb" {
  source = "../../../../modules/compute/aws/alb"
  name   = "rk8s-alb"
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
  security_group_ids          = [var.alb_sg]
  target_groups = {

    distribution = {
      name              = "distribution"
      port              = 8968
      health_check_path = "/healthz"
    }
  }
}


module "distribution" {
  source          = "../../../../modules/compute/aws/ecs"
  region          = var.region
  cluster_name    = "rk8s"
  task_family     = "rk8s-distribution"
  container_name  = "app"
  container_image = "public.ecr.aws/m8q5m4u3/rk8s:distribution-0.1.0-pre-release"
  container_port  = 8968
  service_name    = "distribution"
  cpu             = "512"
  memory          = "1024"
  subnet_ids      = var.public_subnet_ids
  desired_count   = 1

  security_group_ids = [var.ecs_sg]
  environment = [
    {
      "name" : "POSTGRES_HOST",
      "value" : "gitmega.c3aqu4m6k57p.ap-southeast-2.rds.amazonaws.com"
    },
    {
      "name" : "POSTGRES_USER",
      "value" : "${var.db_username}"
    },
    {
      "name" : "POSTGRES_PASSWORD",
      "value" : "${var.db_password}"
    },
    {
      "name" : "POSTGRES_DB",
      "value" : "${var.db_schema}"
    },
    {
      "name" : "GITHUB_CLIENT_ID",
      "value" : "${var.github_client_id}"
    },
    {
      "name" : "GITHUB_CLIENT_SECRET",
      "value" : "${var.github_client_secret}"
    },
    {
      "name" : "OCI_REGISTRY_URL",
      "value" : "0.0.0.0"
    },
  ]

  load_balancers = [{
    target_group_arn = module.alb.target_group_arns["distribution"]
    container_name   = "app"
    container_port   = 8968
    host_headers     = ["${local.distribution_host}"]
    priority         = 601
  }]
  alb_listener_arn = module.alb.https_listener_arn
}
