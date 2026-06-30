output "namespace" {
  description = "Namespace the gitmono stack runs in"
  value       = module.stack.namespace
}

output "datastores" {
  description = "In-cluster datastore service endpoints (apps auto-connect via these hosts)"
  value       = module.stack.datastores
}

output "apps" {
  description = "Deployed gitmono services -> in-cluster Service DNS"
  value       = module.stack.apps
}

output "rustfs_console_url" {
  description = "Public URL of the RustFS web console (requires DNS for the host -> the xuanwu gateway)"
  value       = module.stack.rustfs_console_url
}

output "app_urls" {
  description = "Public URLs per app, including alias hosts (requires DNS for each host -> the xuanwu gateway)"
  value       = module.stack.app_urls
}
