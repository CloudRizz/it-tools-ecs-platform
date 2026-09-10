# This file contains the configuration for the GitHub OIDC provider in AWS IAM.

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-github-oidc"
    }
  )
}