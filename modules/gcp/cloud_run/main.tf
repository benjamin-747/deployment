variable "project_id" { type = string }
variable "service_name" { type = string }
variable "region" { type = string }
variable "image" { type = string }
variable "env_vars" {
  type    = map(string)
  default = {}
}

variable "cpu" {
  type    = string
  default = "1"
}

variable "memory" {
  type    = string
  default = "512Mi"
}

variable "min_instances" {
  type    = number
  default = 0
}

variable "max_instances" {
  type    = number
  default = 10
}

variable "ingress" {
  type    = string
  default = "all"
}

variable "allow_unauth" {
  type    = bool
  default = true
}

variable "vpc_connector" {
  type    = string
  default = null
}

variable "vpc_egress" {
  type        = string
  default     = null
  description = "VPC egress setting. Common values: all-traffic, private-ranges-only"
}

resource "google_cloud_run_service" "this" {
  name     = var.service_name
  project  = var.project_id
  location = var.region

  template {
    spec {
      containers {
        image = var.image
        resources {
          limits = {
            cpu    = var.cpu
            memory = var.memory
          }
        }
        dynamic "env" {
          for_each = var.env_vars
          content {
            name  = env.key
            value = env.value
          }
        }
      }
    }
    metadata {
      annotations = merge(
        {
        "autoscaling.knative.dev/minScale" = tostring(var.min_instances)
        "autoscaling.knative.dev/maxScale" = tostring(var.max_instances)
        },
        var.vpc_connector != null ? {
          "run.googleapis.com/vpc-access-connector" = var.vpc_connector
        } : {},
        var.vpc_egress != null ? {
          "run.googleapis.com/vpc-access-egress" = var.vpc_egress
        } : {}
      )
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
  autogenerate_revision_name = true
}

resource "google_cloud_run_service_iam_member" "invoker" {
  count    = var.allow_unauth ? 1 : 0
  service  = google_cloud_run_service.this.name
  location = google_cloud_run_service.this.location
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "url" {
  value = google_cloud_run_service.this.status[0].url
}
