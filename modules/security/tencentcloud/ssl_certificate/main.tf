locals {
  enabled = var.create_mode != "disabled"

  certificate_name = coalesce(
    var.certificate_name,
    replace(replace(var.domain_name, "*.", "wildcard-"), ".", "-")
  )
}

resource "tencentcloud_ssl_free_certificate" "this" {
  count = var.create_mode == "free" ? 1 : 0

  domain          = var.domain_name
  dv_auth_method  = var.dv_auth_method
  package_type    = var.package_type
  alias           = local.certificate_name
  validity_period = "3" # TrustAsia free DV: 3 months; immutable after apply

  contact_email = var.contact_email != "" ? var.contact_email : null
  contact_phone = var.contact_phone != "" ? var.contact_phone : null

  lifecycle {
    # validity_period is set at create time and cannot be changed afterward.
    ignore_changes = [validity_period]
  }
}

resource "tencentcloud_ssl_check_certificate_domain_verification_operation" "check" {
  count = var.create_mode == "free" && var.auto_complete ? 1 : 0

  certificate_id = tencentcloud_ssl_free_certificate.this[0].id

  depends_on = [tencentcloud_ssl_free_certificate.this]
}

resource "tencentcloud_ssl_complete_certificate_operation" "complete" {
  count = var.create_mode == "free" && var.auto_complete ? 1 : 0

  certificate_id = tencentcloud_ssl_free_certificate.this[0].id

  depends_on = [tencentcloud_ssl_check_certificate_domain_verification_operation.check]
}

resource "tencentcloud_ssl_certificate" "upload" {
  count = var.create_mode == "upload" ? 1 : 0

  type = "SVR"
  cert = trimspace(var.certificate_pem)
  key  = trimspace(var.private_key_pem)
  name = local.certificate_name
}
