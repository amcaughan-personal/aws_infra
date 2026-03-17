variable "role_name" {
  type = string
}

variable "role_description" {
  type    = string
  default = null
}

variable "oidc_provider_arn" {
  type = string
}

variable "provider_url" {
  type    = string
  default = "https://token.actions.githubusercontent.com"
}

variable "allowed_subjects" {
  type = list(string)
}

variable "allowed_audiences" {
  type    = list(string)
  default = ["sts.amazonaws.com"]
}

variable "managed_policy_arns" {
  type    = list(string)
  default = []
}

variable "inline_policy_jsons" {
  type    = map(string)
  default = {}
}

variable "max_session_duration" {
  type    = number
  default = 3600
}
