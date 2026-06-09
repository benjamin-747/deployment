# Authentication:
#   - TF_VAR_tencentcloud_secret_id / TF_VAR_tencentcloud_secret_key
#   - or TENCENTCLOUD_SECRET_ID / TENCENTCLOUD_SECRET_KEY environment variables
#   - optional temporary credentials: TENCENTCLOUD_SECURITY_TOKEN

provider "tencentcloud" {
  secret_id  = var.tencentcloud_secret_id
  secret_key = var.tencentcloud_secret_key
  region     = var.region
}
