# automation

Scheduled account automations live here.

Current stacks:
- `cleanup-janitor`
  Runs once per day and removes explicitly tagged disposable resources.

The janitor is intentionally opt-in. A resource is only eligible for cleanup if it is tagged with:
- `auto_cleanup = true`
- `cleanup_schedule = daily|weekly|monthly`
- `created_on = YYYY-MM-DD`

Default behavior is forgiving:
- if `cleanup_schedule` is missing or invalid, the janitor treats it as `daily`
- if `created_on` is missing:
  - `daily` resources are deleted on the next run
  - `weekly` resources are deleted on Friday
  - `monthly` resources are deleted on the first of the month

The current janitor only acts on a narrow set of resource types:
- EC2 instances
- VPC endpoints
- security groups

That keeps the first version easy to reason about and reduces the chance of it deleting something surprising.
