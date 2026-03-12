# Network Stacks

Shared network resources for internal dev projects live here.

Layout:
- `dev/vpc`
  shared low-cost VPC foundation
- `dev/endpoints`
  shared endpoint bundle for private service access
- `dev/test-host`
  tiny SSM-managed EC2 instance for testing private connectivity from inside the VPC

Intent:
- keep `dev/vpc` up most of the time
- create/destroy `dev/endpoints` when private connectivity is actually needed, for cost reasons ($7 a month is too rich for my blood lol)
- create/destroy `dev/test-host` only when I actually need an in-VPC shell for DNS, curl, or debugging

Current shared endpoint bundle:
- `execute-api` interface endpoint for private API Gateway access
- `s3` gateway endpoint for private subnet access to S3 without NAT

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

If `live/automation/cleanup-janitor` is applied, the test host's EC2 instance, Session Manager VPC endpoints, and helper security groups are tagged for daily cleanup.

Cross-repo consumers should read shared network identifiers from SSM Parameter Store or repo outputs rather than duplicating the VPC in each project repository.
