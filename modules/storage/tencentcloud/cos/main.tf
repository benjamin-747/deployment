# COS bucket names must be globally unique and suffixed with the account APPID,
# e.g. "my-assets-1250000000". The APPID is looked up automatically so callers
# only provide the name prefix (and never confuse APPID with the account UIN).
data "tencentcloud_user_info" "current" {}

resource "tencentcloud_cos_bucket" "this" {
  bucket      = "${var.name}-${data.tencentcloud_user_info.current.app_id}"
  acl         = var.acl
  force_clean = true
  tags        = var.tags
}
