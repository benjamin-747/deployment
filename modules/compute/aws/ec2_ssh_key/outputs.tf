output "key_name" {
  value = aws_key_pair.this.key_name
}

output "public_key_openssh" {
  value = tls_private_key.this.public_key_openssh
}

output "private_key_pem_path" {
  value       = local_file.private_key_pem.filename
  description = "Absolute path to the written .pem file"
}
