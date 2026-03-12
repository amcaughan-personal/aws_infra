variable "name_prefix" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zone_count" {
  type    = number
  default = 1
}

variable "ssm_prefix" {
  type = string
}

variable "publish_ssm_parameters" {
  type    = bool
  default = true
}
