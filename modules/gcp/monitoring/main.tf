resource "google_project_service" "logging" {
  project = var.project_id
  service = "logging.googleapis.com"
}

resource "google_project_service" "monitoring" {
  project = var.project_id
  service = "monitoring.googleapis.com"
}

resource "google_logging_project_sink" "this" {
  count       = var.log_sink_destination != "" ? 1 : 0
  name        = var.log_sink_name != "" ? var.log_sink_name : "${var.app_name}-log-sink"
  project     = var.project_id
  destination = var.log_sink_destination
  filter      = "resource.type=\"cloud_run_revision\""
}

resource "google_monitoring_alert_policy" "pod_restart_high" {
  display_name          = "${var.app_name} Cloud Run Instance Restart Rate High"
  combiner              = "OR"
  enabled               = true
  notification_channels = var.alert_notification_channels

  conditions {
    display_name = "Container restart rate > 5/min"
    condition_threshold {
      filter          = "metric.type=\"run.googleapis.com/container/instance_count\" resource.type=\"cloud_run_revision\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 5
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MAX"
        group_by_fields      = ["resource.label.service_name", "resource.label.location"]
      }
    }
  }

  documentation {
    content = "High instance restart rate detected for ${var.app_name}. Check Cloud Run logs and events."
  }
}

resource "google_monitoring_alert_policy" "sql_connection_failures" {
  display_name          = "${var.app_name} Cloud SQL Connection Failures"
  combiner              = "OR"
  enabled               = true
  notification_channels = var.alert_notification_channels

  conditions {
    display_name = "SQL connection errors > 0"
    condition_threshold {
      filter          = "metric.type=\"cloudsql.googleapis.com/database/network/received_bytes_count\" resource.type=\"cloudsql_database\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.label.database_id"]
      }
    }
  }

  documentation {
    content = "Cloud SQL connection issues detected. Check network connectivity and IAM permissions."
  }
}
