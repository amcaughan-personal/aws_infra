include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id                            = "vpc-00000000000000000"
    vpc_cidr                          = "10.43.0.0/16"
    private_subnet_ids                = ["subnet-00000000000000000"]
    shared_workload_security_group_id = "sg-00000000000000000"
  }

  mock_outputs_allowed_terraform_commands = ["init", "plan", "validate"]
}

terraform {
  source = "${get_repo_root()}/infra/terragrunt/modules/test-host"
}

inputs = {
  instance_type        = "t3.nano"
  name_prefix          = "prod-network-test-host"
  resource_tags = {
    auto_cleanup     = "true"
    cleanup_schedule = "daily"
    created_on       = run_cmd("date", "-u", "+%Y-%m-%d")
  }
  ssm_prefix           = "/network/prod/test-host"
  subnet_id            = dependency.vpc.outputs.private_subnet_ids[0]
  vpc_cidr             = dependency.vpc.outputs.vpc_cidr
  vpc_id               = dependency.vpc.outputs.vpc_id
}
