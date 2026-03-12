# Network Stacks

Shared network resources for internal dev projects live here.

Layout:
- `dev/vpc`
  shared low-cost VPC foundation
- `dev/endpoints`
  shared endpoint bundle for private service access

Intent:
- keep `dev/vpc` up most of the time
- create/destroy `dev/endpoints` when private connectivity is actually needed, for cost reasons ($7 a month is too rich for my blood lol)

Current shared endpoint bundle:
- `execute-api` interface endpoint for private API Gateway access
- `s3` gateway endpoint for private subnet access to S3 without NAT

Cross-repo consumers should read shared network identifiers from SSM Parameter Store or repo outputs rather than duplicating the VPC in each project repository.
