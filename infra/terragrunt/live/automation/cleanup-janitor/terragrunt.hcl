include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "visibility_alerts_sns" {
  config_path = "../../visibility/alerts-sns"

  mock_outputs = {
    topic_arn = "arn:aws:sns:us-east-2:000000000000:visibility-alerts"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}

terraform {
  source = "${get_repo_root()}/infra/terragrunt/modules/cleanup-janitor"
}

inputs = {
  function_name                  = "cleanup-janitor"
  failure_notification_topic_arn = dependency.visibility_alerts_sns.outputs.topic_arn
}
