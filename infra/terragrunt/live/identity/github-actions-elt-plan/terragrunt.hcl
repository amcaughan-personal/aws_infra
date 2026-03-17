include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  elt_state_objects = [
    "live/dev/core/terraform.tfstate",
    "live/dev/sample-api-polling-01/terraform.tfstate",
    "live/dev/sample-file-delivery-01/terraform.tfstate",
    "live/dev/sample-stream-events-01/terraform.tfstate",
    "live/prod/core/terraform.tfstate",
    "live/prod/sample-api-polling-01/terraform.tfstate",
    "live/prod/sample-file-delivery-01/terraform.tfstate",
    "live/prod/sample-stream-events-01/terraform.tfstate",
  ]

  elt_state_lock_objects = [
    for object_key in local.elt_state_objects : "${object_key}.tflock"
  ]

  elt_state_prefixes = [
    "live/dev/core/",
    "live/dev/sample-api-polling-01/",
    "live/dev/sample-file-delivery-01/",
    "live/dev/sample-stream-events-01/",
    "live/prod/core/",
    "live/prod/sample-api-polling-01/",
    "live/prod/sample-file-delivery-01/",
    "live/prod/sample-stream-events-01/",
  ]
}

dependency "github_oidc" {
  config_path = "../github-oidc"

  mock_outputs = {
    provider_arn = "arn:aws:iam::000000000000:oidc-provider/token.actions.githubusercontent.com"
    provider_url = "https://token.actions.githubusercontent.com"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "${get_repo_root()}/infra/terragrunt/modules/github-actions-oidc-role"
}

inputs = {
  role_name        = "github-actions-elt-plan"
  role_description = "GitHub Actions OIDC role for read-only Terragrunt plans in data-simulator-elt"

  oidc_provider_arn = dependency.github_oidc.outputs.provider_arn
  provider_url      = dependency.github_oidc.outputs.provider_url

  allowed_subjects = [
    "repo:amcaughan/data-simulator-elt:pull_request",
    "repo:amcaughan/data-simulator-elt:ref:refs/heads/*",
  ]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
  ]

  inline_policy_jsons = {
    tf_state_backend = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "ReadEltStateBucketMetadata"
          Effect = "Allow"
          Action = [
            "s3:GetBucketLocation",
          ]
          Resource = "arn:aws:s3:::amcaughan-tf-state-us-east-2"
        },
        {
          Sid    = "ListEltStatePrefixes"
          Effect = "Allow"
          Action = [
            "s3:ListBucket",
          ]
          Resource = "arn:aws:s3:::amcaughan-tf-state-us-east-2"
          Condition = {
            StringLike = {
              "s3:prefix" = local.elt_state_prefixes
            }
          }
        },
        {
          Sid    = "ReadEltStateObjects"
          Effect = "Allow"
          Action = [
            "s3:GetObject",
          ]
          Resource = [
            for object_key in local.elt_state_objects : "arn:aws:s3:::amcaughan-tf-state-us-east-2/${object_key}"
          ]
        },
        {
          Sid    = "ManageEltStateLockObjects"
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
          ]
          Resource = [
            for object_key in local.elt_state_lock_objects : "arn:aws:s3:::amcaughan-tf-state-us-east-2/${object_key}"
          ]
        },
      ]
    })
  }
}
