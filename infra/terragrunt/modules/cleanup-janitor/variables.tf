variable "function_name" {
  type = string
}

variable "schedule_expression" {
  type    = string
  default = "cron(15 6 * * ? *)"
}

variable "reserved_concurrent_executions" {
  type    = number
  default = 1
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "cleanup_tag_name" {
  type    = string
  default = "auto_cleanup"
}

variable "accepted_cleanup_tag_names" {
  type    = list(string)
  default = ["auto-cleanup", "auto_delete", "auto-delete"]
}

variable "cleanup_schedule_tag_name" {
  type    = string
  default = "cleanup_schedule"
}

variable "cleanup_ttl_tag_name" {
  type    = string
  default = "cleanup_ttl"
}

variable "accepted_cleanup_ttl_tag_names" {
  type    = list(string)
  default = ["cleanup-ttl", "ttl"]
}

variable "created_on_tag_name" {
  type    = string
  default = "created_on"
}

variable "created_at_tag_name" {
  type    = string
  default = "created_at"
}

variable "weekly_cleanup_weekday" {
  type    = string
  default = "fri"

  validation {
    condition = contains(
      ["mon", "tue", "wed", "thu", "fri", "sat", "sun"],
      var.weekly_cleanup_weekday,
    )
    error_message = "weekly_cleanup_weekday must be one of mon, tue, wed, thu, fri, sat, or sun."
  }
}

variable "monthly_cleanup_day" {
  type    = number
  default = 1

  validation {
    condition     = var.monthly_cleanup_day >= 1 && var.monthly_cleanup_day <= 31
    error_message = "monthly_cleanup_day must be between 1 and 31."
  }
}
