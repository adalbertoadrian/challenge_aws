variable "access_key" {
  description = "access_key"
  type        = string
  sensitive   = true
}
variable "secret_key" {
  description = "secret_key"
  type        = string
  sensitive   = true
}
variable "database_user" {
  description = "database_user"
  type        = string
  sensitive   = true
}
variable "database_password" {
  description = "database_password"
  type        = string
  sensitive   = true
}
variable "webapplication_bucket" {
  description = "webapplication_bucket"
  type        = string
  sensitive   = true
}
variable "aws_account_id" {
  description = "webapplication_bucket"
  type        = string
  sensitive   = true
}
variable "sns_topic" {
  description = "sns_topic"
  type        = string
  sensitive   = true
}