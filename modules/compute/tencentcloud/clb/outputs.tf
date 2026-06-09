output "clb_id" {
  description = "CLB instance ID"
  value       = tencentcloud_clb_instance.this.id
}

output "domain" {
  description = "CLB domain name"
  value       = tencentcloud_clb_instance.this.domain
}

output "vips" {
  description = "CLB virtual IP address list"
  value       = tencentcloud_clb_instance.this.clb_vips
}

output "http_listener_id" {
  description = "HTTP listener ID"
  value       = tencentcloud_clb_listener.http.listener_id
}

output "https_listener_id" {
  description = "HTTPS listener ID (null when no certificate provided)"
  value       = local.https_enabled ? tencentcloud_clb_listener.https[0].listener_id : null
}

output "active_listener_id" {
  description = "Listener ID used by forwarding rules (HTTPS when a certificate is set, otherwise HTTP)"
  value       = local.listener_id
}

output "listener_rule_ids" {
  description = "Listener rule IDs keyed by service name"
  value       = { for k, r in tencentcloud_clb_listener_rule.rules : k => r.rule_id }
}
