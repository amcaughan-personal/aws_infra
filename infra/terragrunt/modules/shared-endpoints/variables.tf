variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "private_route_table_ids" {
  type = list(string)
}

variable "enable_execute_api" {
  type    = bool
  default = true
}

variable "enable_s3_gateway" {
  type    = bool
  default = true
}

variable "ssm_prefix" {
  type = string
}

variable "publish_ssm_parameters" {
  type    = bool
  default = true
}
