output "instance_id" {
  value = aws_instance.this.id
}

output "public_ip" {
  value = aws_instance.this.public_ip
}

output "root_volume_id" {
  value = aws_instance.this.root_block_device[0].volume_id
}