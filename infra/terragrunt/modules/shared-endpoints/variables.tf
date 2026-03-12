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

variable "auto_cleanup_enabled" {
  type    = bool
  default = false
}

variable "cleanup_schedule" {
  type    = string
  default = "daily"

  validation {
    condition     = contains(["daily", "weekly", "monthly"], var.cleanup_schedule)
    error_message = "cleanup_schedule must be daily, weekly, or monthly."
  }
}

variable "cleanup_tag_name" {
  type    = string
  default = "auto_cleanup"
}

variable "cleanup_schedule_tag_name" {
  type    = string
  default = "cleanup_schedule"
}

variable "created_on_tag_name" {
  type    = string
  default = "created_on"
}
