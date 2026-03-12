include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/terragrunt/modules/shared-vpc"
}

inputs = {
  name_prefix = "prod-shared"
  vpc_cidr    = "10.43.0.0/16"
  # Keep prod cost-conscious for now. Expand later if I need multi-AZ behavior testing.
  availability_zone_count = 1
  ssm_prefix              = "/network/prod/vpc"
}
