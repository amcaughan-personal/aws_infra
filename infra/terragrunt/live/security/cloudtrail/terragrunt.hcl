include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/terragrunt//modules/cloudtrail"
}

inputs = {
  trail_name        = "account-trail"
  log_group_name    = "/aws/cloudtrail/account-trail"
  retention_in_days = 30

  bucket_name   = null # default
  bucket_prefix = "cloudtrail-logs"
  # Sandbox teardown is part of the normal workflow here, so empty the
  # versioned log bucket automatically instead of requiring manual cleanup.
  force_destroy_bucket = true

  enable_delivery_notifications = false
  delivery_notification_topic_name = "cloudtrail-log-delivery"
}
