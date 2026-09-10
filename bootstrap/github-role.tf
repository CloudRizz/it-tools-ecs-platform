# Defines the trust relationship that allows GitHub Actions from this repository's
# main branch to securely assume an AWS IAM role using OIDC, avoiding long-lived AWS credentials.

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:CloudRizz/it-tools-ecs-platform:ref:refs/heads/main"
      ]
    }
  }
}

# IAM role assumed by GitHub Actions after the OIDC token satisfies the trust policy.
# AWS permissions for the CI/CD pipeline are attached to this role separately.

resource "aws_iam_role" "github_actions" {
  name = "${local.project_name}-github-actions-role"

  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-github-actions-role"
    }
  )
}

# Defines the AWS services the GitHub Actions pipeline can use to
# provision infrastructure with Terraform and deploy the application.
data "aws_iam_policy_document" "github_actions_permissions" {

  statement {
    sid    = "EC2Networking"
    effect = "Allow"

    actions = [
      "ec2:*"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ECS"
    effect = "Allow"

    actions = [
      "ecs:*"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ECR"
    effect = "Allow"

    actions = [
      "ecr:*"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "LoadBalancing"
    effect = "Allow"

    actions = [
      "elasticloadbalancing:*"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:*"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ACM"
    effect = "Allow"

    actions = [
      "acm:*"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "TerraformStateBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketVersioning",
      "s3:GetBucketLocation"
    ]

    resources = [
      aws_s3_bucket.terraform_state.arn
    ]
  }

  statement {
    sid    = "TerraformStateObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.terraform_state.arn}/infra/*"
    ]
  }

  statement {
    sid    = "Route53"
    effect = "Allow"

    actions = [
      "route53:*"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "IAM"
    effect = "Allow"

    actions = [
      "iam:GetRole",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PassRole",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:ListPolicyVersions",
      "iam:TagPolicy",
      "iam:UntagPolicy"
    ]

    resources = ["*"]
  }
}


# # Defines the AWS permissions required by the GitHub Actions CI/CD pipeline
# to build, deploy and manage the IT Tools infrastructure.

resource "aws_iam_policy" "github_actions" {
  name        = "${local.project_name}-github-actions-policy"
  description = "Permissions for the IT Tools Github Actions deployment pipeline"

  policy = data.aws_iam_policy_document.github_actions_permissions.json

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-github-actions-policy"
    }
  )
}

# Attaches the deployment permissions to the GitHub Actions IAM role.
resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}