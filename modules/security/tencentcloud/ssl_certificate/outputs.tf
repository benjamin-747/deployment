output "certificate_id" {
  description = "SSL certificate ID for CLB HTTPS listener. Null when create_mode is disabled."
  value = (
    var.create_mode == "disabled" ? null :
    var.create_mode == "existing" ? var.certificate_id :
    var.create_mode == "upload" ? tencentcloud_ssl_certificate.upload[0].id :
    tencentcloud_ssl_free_certificate.this[0].id
  )
}

output "domain_validation_records" {
  description = "DNS records to add for free certificate DV validation (when dv_auth_method is DNS or DNS_AUTO pending)."
  value       = var.create_mode == "free" ? tencentcloud_ssl_free_certificate.this[0].dv_auths : []
}

output "status_name" {
  description = "Free certificate status label from Tencent Cloud."
  value       = var.create_mode == "free" ? tencentcloud_ssl_free_certificate.this[0].status_name : null
}

output "deployable" {
  description = "Whether the free certificate can be deployed to CLB/CDN."
  value       = var.create_mode == "free" ? tencentcloud_ssl_free_certificate.this[0].deployable : null
}
