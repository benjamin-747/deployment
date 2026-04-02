variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "app_name" {
  type        = string
  description = "The name of the application, used as a prefix for all resources"
}

variable "alert_notification_channels" {
  type        = list(string)
  default     = []
  description = "List of notification channel IDs for alerts"
}

variable "log_sink_name" {
  type        = string
  default     = ""
  description = "Optional log sink name for exporting logs"
}

variable "log_sink_destination" {
  type        = string
  default     = ""
  description = "Optional log sink destination (e.g., bigquery.googleapis.com/projects/PROJECT_ID/datasets/DATASET_ID)"
}
