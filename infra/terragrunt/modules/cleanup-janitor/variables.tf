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

variable "failure_notification_topic_arn" {
  type    = string
  default = ""
}

variable "cleanup_tag_names" {
  type        = list(string)
  description = "Accepted auto-cleanup tag keys. The first entry is the canonical key new stacks should publish."
  default     = ["auto_cleanup", "auto-cleanup", "auto_delete", "auto-delete"]

  validation {
    condition     = length(var.cleanup_tag_names) > 0
    error_message = "cleanup_tag_names must contain at least one tag key."
  }
}

variable "cleanup_schedule_tag_name" {
  type    = string
  default = "cleanup_schedule"
}

variable "cleanup_ttl_tag_names" {
  type        = list(string)
  description = "Accepted TTL tag keys. The first entry is the canonical key new stacks should publish."
  default     = ["cleanup_ttl", "cleanup-ttl", "ttl"]

  validation {
    condition     = length(var.cleanup_ttl_tag_names) > 0
    error_message = "cleanup_ttl_tag_names must contain at least one tag key."
  }
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
