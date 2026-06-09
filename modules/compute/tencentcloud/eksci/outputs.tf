output "id" {
  description = "EKSCI instance ID"
  value       = tencentcloud_eks_container_instance.this.id
}

output "private_ip" {
  description = "VPC private IP (use as CLB backend eni_ip)"
  value       = tencentcloud_eks_container_instance.this.private_ip
}

output "eip_address" {
  description = "Public EIP when auto_create_eip is enabled"
  value       = tencentcloud_eks_container_instance.this.eip_address
}

output "status" {
  description = "Instance status"
  value       = tencentcloud_eks_container_instance.this.status
}
