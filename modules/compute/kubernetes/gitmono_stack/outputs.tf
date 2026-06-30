output "namespace" {
  description = "Namespace the gitmono stack runs in"
  value       = kubernetes_namespace_v1.this.metadata[0].name
}

output "datastores" {
  description = "In-cluster datastore service endpoints (apps auto-connect via these hosts)"
  value = {
    postgresql = var.enable_postgresql ? "postgresql.${var.namespace}.svc.cluster.local:5432/${var.pg_database}" : null
    mysql      = var.enable_mysql ? "mysql.${var.namespace}.svc.cluster.local:3306/${var.mysql_database}" : null
    redis      = var.enable_redis ? "redis-master.${var.namespace}.svc.cluster.local:6379" : null
    rustfs_s3  = var.enable_rustfs ? "http://rustfs.${var.namespace}.svc.cluster.local:9000 (bucket: ${var.rustfs_bucket})" : null
    rustfs_ui  = var.enable_rustfs ? "rustfs.${var.namespace}.svc.cluster.local:9001 (console)" : null
  }
}

output "apps" {
  description = "Deployed gitmono services -> in-cluster Service DNS"
  value = var.enable_apps ? {
    for name, m in module.apps : name => "${m.service_name}.${var.namespace}.svc.cluster.local"
  } : {}
}

output "rustfs_console_url" {
  description = "Public URL of the RustFS web console (requires DNS for the host -> the xuanwu gateway)"
  value       = var.enable_rustfs && var.enable_rustfs_console_ingress ? "https://${var.rustfs_console_subdomain}.${var.base_domain}" : null
}

output "app_urls" {
  description = "Public URLs per app, including alias hosts (requires DNS for each host -> the xuanwu gateway)"
  value = var.enable_apps ? {
    for k in keys(var.app_subdomains) : k => [
      for h in concat([var.app_subdomains[k]], lookup(var.app_alias_subdomains, k, [])) : "https://${h}.${var.base_domain}"
    ]
  } : {}
}
