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

variable "enable_ecr_api" {
  type    = bool
  default = false
}

variable "enable_ecr_dkr" {
  type    = bool
  default = false
}

variable "enable_logs" {
  type    = bool
  default = false
}

variable "enable_ssm" {
  type    = bool
  default = false
}

variable "enable_athena" {
  type    = bool
  default = false
}

variable "enable_glue" {
  type    = bool
  default = false
}

variable "enable_sts" {
  type    = bool
  default = false
}

variable "enable_kinesis_streams" {
  type    = bool
  default = false
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
