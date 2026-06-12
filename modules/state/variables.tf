variable "name_prefix" {
  type        = string
  description = "Prefix used for naming all resources"
}

variable "account_id" {
  type        = string
  description = "AWS account ID for creating unique bucket names"
}

variable "create_locking_table" {
  type        = bool
  default     = true
  description = "Whether to create a DynamoDB table for state locking"
}
