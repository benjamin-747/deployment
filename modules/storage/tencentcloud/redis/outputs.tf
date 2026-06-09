output "instance_id" {
  description = "Redis instance ID"
  value       = tencentcloud_redis_instance.this.id
}

output "ip" {
  description = "Redis private IP"
  value       = tencentcloud_redis_instance.this.ip
}

output "port" {
  description = "Redis access port"
  value       = var.port
}

output "endpoint" {
  description = "Redis host:port endpoint"
  value       = "${tencentcloud_redis_instance.this.ip}:${var.port}"
}
