include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id                            = "vpc-00000000000000000"
    vpc_cidr                          = "10.42.0.0/16"
    private_subnet_ids                = ["subnet-00000000000000000"]
    private_route_table_ids           = ["rtb-00000000000000000"]
    shared_workload_security_group_id = "sg-00000000000000000"
  }

  mock_outputs_allowed_terraform_commands = ["init", "plan", "validate"]
}

terraform {
  source = "${get_repo_root()}/infra/terragrunt/modules/shared-endpoints"
}

inputs = {
  extra_default_tags = {
    auto_cleanup     = "true"
    cleanup_schedule = "weekly"
    created_on       = run_cmd("date", "-u", "+%Y-%m-%d")
  }
  name_prefix             = "dev-shared"
  vpc_id                  = dependency.vpc.outputs.vpc_id
  vpc_cidr                = dependency.vpc.outputs.vpc_cidr
  private_subnet_ids      = dependency.vpc.outputs.private_subnet_ids
  private_route_table_ids = dependency.vpc.outputs.private_route_table_ids
  # Private ECS workloads need more than the API endpoint once ELT jobs live in the VPC.
  enable_execute_api      = true
  enable_ecr_api          = true
  enable_ecr_dkr          = true
  enable_logs             = true
  enable_ssm              = true
  enable_athena           = true
  enable_glue             = true
  enable_sts              = true
  enable_kinesis_streams  = true
  enable_s3_gateway       = true
  ssm_prefix              = "/network/dev/endpoints"
}
