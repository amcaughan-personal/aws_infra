variable "log_group_name" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "period_seconds" {
  type    = number
  default = 300
}

variable "eval_periods" {
  type    = number
  default = 1
}

variable "console_login_failure_threshold" {
  type    = number
  default = 5
}
