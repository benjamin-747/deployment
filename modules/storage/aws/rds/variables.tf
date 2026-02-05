variable "engine" {}
variable "engine_version" {}
variable "identifier" {}
variable "instance_class" {}
variable "allocated_storage" {}
variable "storage_type" {}
variable "username" {}
variable "password" {}
variable "db_name" {}
variable "publicly_accessible" { default = true }
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }