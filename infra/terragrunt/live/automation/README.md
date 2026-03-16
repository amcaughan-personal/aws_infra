# automation

Scheduled account automations live here.

Current stacks:
- `cleanup-janitor`
  Runs once per day and removes explicitly tagged disposable resources.
  It can also send failure emails when a cleanup action fails or when the Lambda itself errors.

The janitor is intentionally opt-in. A resource is only eligible for cleanup if it is tagged with:
- `auto_cleanup = true`
- `cleanup_schedule = daily|weekly|monthly`
- `created_on = YYYY-MM-DD`

TTL cleanup is also supported. If a resource has a TTL tag, the janitor uses that instead of the legacy schedule tags:
- `cleanup_ttl = <number>[m|h|d|w]`
- optional `created_at = YYYY-MM-DDTHH:MM:SSZ`

Examples:
- `cleanup_ttl = 12h`
- `cleanup_ttl = 7d`
- `cleanup_ttl = 2w`

If `created_at` is missing, TTL cleanup falls back to `created_on` at midnight UTC.

The janitor accepts a small explicit set of opt-in tag keys:
- `auto_cleanup`
- `auto-cleanup`
- `auto_delete`
- `auto-delete`

The janitor module now models these as ordered lists:
- `cleanup_tag_names`
- `cleanup_ttl_tag_names`

The first entry in each list is the canonical key that new stacks should publish.

Those same tag keys are used to scope the janitor's IAM permissions, so destructive actions are limited to resources that carry one of the accepted opt-in tags with value `true`.

Default behavior is forgiving:
- `cleanup_schedule` values are normalized for case and punctuation, so values like `Daily`, `WEEK-LY`, and `month_ly` still work
- if `cleanup_schedule` is missing or invalid, the janitor treats it as `daily`
- if `cleanup_schedule` is malformed, the janitor deletes on the next run as a daily cleanup
- if `cleanup_ttl` is present, it takes precedence over `cleanup_schedule`
- if `cleanup_ttl` is malformed, the janitor deletes on the next run
- if `cleanup_ttl` is present but both `created_at` and `created_on` are missing, the janitor deletes on the next run
- if `created_on` is missing:
  - `daily` resources are deleted on the next run
  - `weekly` resources are deleted on Friday
  - `monthly` resources are deleted on the first of the month
- if `created_on` is malformed, the janitor deletes on the next run as a daily cleanup

The current janitor acts on these tagged resource types:
- Athena workgroups
- CloudWatch log groups
- ECR repositories
- EC2 instances
- ECS tasks
- Firehose delivery streams
- Glue databases and their tables
- Kinesis streams
- S3 buckets
- Scheduler schedules
- VPC endpoints
- security groups

This is intentionally broad for disposable sandbox stacks, but it is still opt-in. Untagged resources are ignored.

Optional failure notifications:
- by default, the `cleanup-janitor` live stack reuses the shared `visibility-alerts` SNS topic
- the janitor module expects an existing SNS topic ARN rather than creating its own topic
- the janitor publishes an email when a tagged resource cleanup fails
- a CloudWatch alarm on Lambda `Errors` publishes to the same topic for full invocation failures
