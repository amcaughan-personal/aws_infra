include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/terragrunt/modules/shared-vpc"
}

inputs = {
  name_prefix = "dev-shared"
  vpc_cidr    = "10.42.0.0/16"
  # Single-AZ keeps the dev network cheap. Expand later if a project needs HA testing.
  availability_zone_count = 1
  ssm_prefix              = "/network/dev/vpc"
}
