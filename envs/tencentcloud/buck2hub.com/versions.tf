terraform {
  required_version = ">= 1.15.0"

  required_providers {
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = ">= 1.82.101"
    }
  }
}
