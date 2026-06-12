variable "name_prefix" {
  type        = string
  description = "Prefix used for naming all resources"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC"
}

variable "az_count" {
  type        = number
  default     = 2
  description = "Number of availability zones to use"
}

variable "az_names" {
  type        = list(string)
  description = "List of availability zone names"
}

variable "create_nat_gateway" {
  type        = bool
  default     = false
  description = "Whether to create a NAT Gateway for private subnets (adds ~$32/mo)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
