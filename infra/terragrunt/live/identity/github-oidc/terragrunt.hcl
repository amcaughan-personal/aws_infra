include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/terragrunt/modules/github-oidc-provider"
}

inputs = {
  # Shared account-level GitHub Actions federation trust. Individual repo roles
  # should consume this provider rather than each repo defining its own IdP.
  provider_url = "https://token.actions.githubusercontent.com"
  client_id_list = [
    "sts.amazonaws.com",
  ]
}
