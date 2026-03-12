include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id                      = "vpc-00000000000000000"
    vpc_cidr                    = "10.42.0.0/16"
    private_subnet_ids          = ["subnet-00000000000000000"]
    private_route_table_ids     = ["rtb-00000000000000000"]
    shared_workload_security_group_id = "sg-00000000000000000"
  }

  mock_outputs_allowed_terraform_commands = ["init", "plan", "validate"]
}

terraform {
  source = "${get_repo_root()}/infra/terragrunt/modules/shared-endpoints"
}

inputs = {
  name_prefix            = "dev-shared"
  vpc_id                 = dependency.vpc.outputs.vpc_id
  vpc_cidr               = dependency.vpc.outputs.vpc_cidr
  private_subnet_ids     = dependency.vpc.outputs.private_subnet_ids
  private_route_table_ids = dependency.vpc.outputs.private_route_table_ids
  # Keep only the shared endpoints that current internal projects actually need.
  enable_execute_api     = true
  enable_s3_gateway      = true
  # Uncomment if I ever want the shared endpoint layer to be disposable too.
  # auto_cleanup_enabled = true
  # cleanup_schedule    = "daily"
  ssm_prefix             = "/network/dev/endpoints"
}
