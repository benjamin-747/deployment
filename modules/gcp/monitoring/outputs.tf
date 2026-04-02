output "log_sink_writer_identity" {
  description = "Writer identity for the optional log sink"
  value       = try(google_logging_project_sink.this[0].writer_identity, null)
}
