output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of all public subnets"
  value       = [for s in aws_subnet.public : s.id]
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "igw_id" {
  value = aws_internet_gateway.igw.id
}