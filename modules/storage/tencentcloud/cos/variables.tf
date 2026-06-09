variable "name" {
  type        = string
  description = "COS bucket name prefix (without APPID). The account APPID is appended automatically."
}

variable "region" {
  type        = string
  description = "Tencent Cloud region for the bucket"
}

variable "acl" {
  type        = string
  description = "Bucket ACL (e.g. private)"
  default     = "private"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the bucket"
  default     = {}
}
