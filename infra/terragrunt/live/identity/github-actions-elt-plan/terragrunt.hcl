include "root" {
  path = find_in_parent_folders("root.hcl")
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
              "s3:prefix" = [
                "live/dev/*",
                "live/prod/*",
              ]
            }
          }
        },
        {
          Sid    = "ReadWriteEltStateObjects"
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
          ]
          Resource = [
            "arn:aws:s3:::amcaughan-tf-state-us-east-2/live/dev/*",
            "arn:aws:s3:::amcaughan-tf-state-us-east-2/live/prod/*",
          ]
        },
      ]
    })
  }
}
