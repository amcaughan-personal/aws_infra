# automation

Scheduled account automations live here.

Current stacks:
- `cleanup-janitor`
  Runs once per day and removes explicitly tagged disposable resources.

The janitor is intentionally opt-in. A resource is only eligible for cleanup if it is tagged with:
- `auto_cleanup = true`
- `cleanup_schedule = daily|weekly|monthly`
- `created_on = YYYY-MM-DD`

The current janitor only acts on a narrow set of resource types:
- EC2 instances
- VPC endpoints
- security groups

That keeps the first version easy to reason about and reduces the chance of it deleting something surprising.
