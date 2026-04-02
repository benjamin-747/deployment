variable "name" {
  type        = string
  description = "Base name; creates AWS key pair \"{name}-key\" and writes \"{name}-key.pem\" next to the ec2 module (for stable paths in docs)."
}

variable "rsa_bits" {
  type    = number
  default = 4096
}
