variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.nano"
}

variable "ssm_prefix" {
  type = string
}

variable "publish_ssm_parameters" {
  type    = bool
  default = true
}
