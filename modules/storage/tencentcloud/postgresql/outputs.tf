output "instance_id" {
  description = "PostgreSQL instance ID"
  value       = tencentcloud_postgresql_instance.this.id
}

output "private_ip" {
  description = "Private access IP"
  value       = tencentcloud_postgresql_instance.this.private_access_ip
}

output "private_port" {
  description = "Private access port"
  value       = tencentcloud_postgresql_instance.this.private_access_port
}

output "endpoint" {
  description = "Private host:port endpoint"
  value       = "${tencentcloud_postgresql_instance.this.private_access_ip}:${tencentcloud_postgresql_instance.this.private_access_port}"
}

output "database" {
  description = "Default database name used by the application"
  value       = var.db_schema
}
