include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/terragrunt/modules/cleanup-janitor"
}

inputs = {
  function_name = "cleanup-janitor"
}
