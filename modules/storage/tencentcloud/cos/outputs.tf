output "bucket_name" {
  description = "Full COS bucket name (prefix-APPID)"
  value       = tencentcloud_cos_bucket.this.bucket
}

output "bucket_url" {
  description = "COS bucket endpoint URL"
  value       = "https://${tencentcloud_cos_bucket.this.bucket}.cos.${var.region}.myqcloud.com"
}
