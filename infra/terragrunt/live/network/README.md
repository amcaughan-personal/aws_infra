# Network Stacks

Shared network resources for internal dev projects live here.

Layout:
- `dev/vpc`
  shared low-cost VPC foundation
- `dev/endpoints`
  shared endpoint bundle for private service access
- `dev/test-host`
  tiny SSM-managed EC2 instance for testing private connectivity from inside the VPC
- `prod/vpc`
  shared low-cost VPC foundation for production-scoped internal services
- `prod/endpoints`
  shared endpoint bundle for production-scoped private service access
- `prod/test-host`
  tiny SSM-managed EC2 instance for testing private connectivity from inside the prod VPC

Intent:
- keep `dev/vpc` up most of the time
- create/destroy `dev/endpoints` when private connectivity is actually needed, for cost reasons ($7 a month is too rich for my blood lol)
- create/destroy `dev/test-host` only when I actually need an in-VPC shell for DNS, curl, or debugging
- keep `prod/vpc` up when I want a real prod-scoped network boundary
- create/destroy `prod/test-host` only when I need an in-VPC prod shell for DNS, curl, or debugging
- let the janitor sweep both `dev/endpoints` and `prod/endpoints` weekly so I do not forget and pay for idle interface endpoints

Current shared endpoint bundle:
- `execute-api` interface endpoint for private API Gateway access
- `ecr.api` and `ecr.dkr` interface endpoints for private ECS image pulls
- `logs` interface endpoint for private ECS and Firehose logging
- `ssm` interface endpoint for private runtime configuration lookups
- `athena` and `glue` interface endpoints for private ELT query and catalog access
- `sts` interface endpoint for private ELT and Athena identity resolution
- `kinesis-streams` interface endpoint for private streaming workflow emission
- `s3` gateway endpoint for private subnet access to S3 without NAT
- weekly cleanup tagging so the janitor can remove the costly endpoint layer if I forget

Current test host stack:
- one `t3.nano` Amazon Linux instance in the shared private subnet
- no SSH or public IP
- SSM Session Manager access through dedicated `ssm`, `ssmmessages`, and `ec2messages` interface endpoints in the same stack
- opt-in cleanup tags so the janitor can remove the costly pieces if I forget

Quick loop:
- `cd infra/terragrunt/live/network/dev/test-host`
- `terragrunt apply`
- `terragrunt output -raw start_session_command`
- run the returned `aws ssm start-session ...` command
- `exit` when done
- `terragrunt destroy` when I no longer need the box

Prod uses the same flow:
- `cd infra/terragrunt/live/network/prod/test-host`
- `terragrunt apply`
- `terragrunt output -raw start_session_command`
- run the returned `aws ssm start-session ...` command
- `exit` when done
- `terragrunt destroy` when I no longer need the box

If `live/automation/cleanup-janitor` is applied, both test-host stacks tag their EC2 instance, Session Manager VPC endpoints, and helper security groups for daily cleanup.

Cross-repo consumers should read shared network identifiers from SSM Parameter Store or repo outputs rather than duplicating the VPC in each project repository.

Foundational shared VPC resources are intentionally not tagged for janitor cleanup.
The janitor tags are reserved for disposable high-cost layers like endpoint bundles
and test hosts.
