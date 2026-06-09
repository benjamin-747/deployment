locals {
  https_enabled = var.enable_https
  listener_id   = local.https_enabled ? tencentcloud_clb_listener.https[0].listener_id : tencentcloud_clb_listener.http.listener_id
}

# OPEN = public-facing CLB (analogous to an internet-facing AWS ALB).
resource "tencentcloud_clb_instance" "this" {
  network_type    = "OPEN"
  clb_name        = var.name
  vpc_id          = var.vpc_id
  security_groups = var.security_group_ids
  tags            = var.tags
}

resource "tencentcloud_clb_listener" "http" {
  clb_id        = tencentcloud_clb_instance.this.id
  listener_name = "${var.name}-http"
  port          = var.http_port
  protocol      = "HTTP"
}

resource "tencentcloud_clb_listener" "https" {
  count = local.https_enabled ? 1 : 0

  clb_id               = tencentcloud_clb_instance.this.id
  listener_name        = "${var.name}-https"
  port                 = var.https_port
  protocol             = "HTTPS"
  certificate_ssl_mode = "UNIDIRECTIONAL"
  certificate_id       = var.certificate_id
}

# Host-based routing rules (NODE backends). Pod IPs are registered via
# tencentcloud_clb_attachment in the env layer (clb_backends.tf).
#
# Target groups (v1/v2) are in beta and not enabled on all accounts; NODE
# mode does not require CreateTargetGroup whitelist.
resource "tencentcloud_clb_listener_rule" "rules" {
  for_each = var.target_groups

  clb_id      = tencentcloud_clb_instance.this.id
  listener_id = local.listener_id
  domain      = each.value.domain
  url         = each.value.url

  forward_type           = "HTTP"
  target_type            = "NODE"
  scheduler              = "WRR"
  health_check_switch    = true
  health_check_http_path = each.value.health_check_path
}
