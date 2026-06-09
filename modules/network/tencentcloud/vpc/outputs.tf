output "vpc_id" {
  description = "VPC ID"
  value       = tencentcloud_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of all public subnets"
  value       = [for s in tencentcloud_subnet.public : s.id]
}
