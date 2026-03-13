# automation

Scheduled account automations live here.

Current stacks:
- `cleanup-janitor`
  Runs once per day and removes explicitly tagged disposable resources.

The janitor is intentionally opt-in. A resource is only eligible for cleanup if it is tagged with:
- `auto_cleanup = true`
- `cleanup_schedule = daily|weekly|monthly`
- `created_on = YYYY-MM-DD`

The janitor accepts a small explicit set of opt-in tag keys:
- `auto_cleanup`
- `auto-cleanup`
- `auto_delete`
- `auto-delete`

Those same tag keys are used to scope the janitor's IAM permissions, so destructive actions are limited to resources that carry one of the accepted opt-in tags with value `true`.

Default behavior is forgiving:
- `cleanup_schedule` values are normalized for case and punctuation, so values like `Daily`, `WEEK-LY`, and `month_ly` still work
- if `cleanup_schedule` is missing or invalid, the janitor treats it as `daily`
- if `cleanup_schedule` is malformed, the janitor deletes on the next run as a daily cleanup
- if `created_on` is missing:
  - `daily` resources are deleted on the next run
  - `weekly` resources are deleted on Friday
  - `monthly` resources are deleted on the first of the month
- if `created_on` is malformed, the janitor deletes on the next run as a daily cleanup

The current janitor only acts on a narrow set of resource types:
- EC2 instances
- VPC endpoints
- security groups
- ECS tasks

That keeps the first version easy to reason about and reduces the chance of it deleting something surprising.
