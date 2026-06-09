output "clb_domain" {
  description = "Public CLB domain — CNAME each service host (git/app/api/...) to this name"
  value       = module.clb.domain
}

output "clb_vips" {
  description = "CLB VIP addresses (alternative to CNAME if your DNS provider requires A records)"
  value       = module.clb.vips
}

output "ssl_certificate_id" {
  description = "SSL certificate ID bound to the CLB HTTPS listener (null when ssl_create_mode is disabled)"
  value       = module.ssl_certificate.certificate_id
}

output "ssl_domain_validation_records" {
  description = "DNS records to add for free certificate validation (empty when not using free mode)"
  value       = module.ssl_certificate.domain_validation_records
}

output "eksci" {
  description = "EKSCI container instances keyed by service name (when enable_eksci=true)"
  value = var.enable_eksci ? {
    for name, inst in module.eksci : name => {
      id         = inst.id
      private_ip = inst.private_ip
      eip        = inst.eip_address
      status     = inst.status
    }
  } : null
}
