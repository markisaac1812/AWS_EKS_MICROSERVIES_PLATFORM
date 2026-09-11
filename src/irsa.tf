############################################
# IAM Roles for Service Accounts (IRSA)
# Least-privilege access from pods to AWS services, scoped per
# workload group rather than granting node-wide IAM permissions.
############################################

# ---------- core-services: auth, users, reservations tables ----------
data "aws_iam_policy_document" "core_services_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:core-services:core-services-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "core_services" {
  name               = "${local.name}-core-services-irsa"
  assume_role_policy = data.aws_iam_policy_document.core_services_assume.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "core_services_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
    ]
    resources = [
      aws_dynamodb_table.tables["auth"].arn,
      aws_dynamodb_table.tables["users"].arn,
      aws_dynamodb_table.tables["reservations"].arn,
      "${aws_dynamodb_table.tables["auth"].arn}/index/*",
      "${aws_dynamodb_table.tables["users"].arn}/index/*",
      "${aws_dynamodb_table.tables["reservations"].arn}/index/*",
    ]
  }
}

resource "aws_iam_role_policy" "core_services" {
  name   = "${local.name}-core-services-policy"
  role   = aws_iam_role.core_services.id
  policy = data.aws_iam_policy_document.core_services_policy.json
}

# ---------- commerce-services: media (S3+DynamoDB), payment, sessions ----------
data "aws_iam_policy_document" "commerce_services_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:commerce-services:commerce-services-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "commerce_services" {
  name               = "${local.name}-commerce-services-irsa"
  assume_role_policy = data.aws_iam_policy_document.commerce_services_assume.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "commerce_services_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
    ]
    resources = [
      aws_dynamodb_table.tables["media"].arn,
      aws_dynamodb_table.tables["payment"].arn,
      aws_dynamodb_table.tables["sessions"].arn,
      "${aws_dynamodb_table.tables["media"].arn}/index/*",
      "${aws_dynamodb_table.tables["payment"].arn}/index/*",
      "${aws_dynamodb_table.tables["sessions"].arn}/index/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.media.arn,
      "${aws_s3_bucket.media.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "commerce_services" {
  name   = "${local.name}-commerce-services-policy"
  role   = aws_iam_role.commerce_services.id
  policy = data.aws_iam_policy_document.commerce_services_policy.json
}

# ---------- search-services: Aurora + RDS (via Secrets Manager) ----------
data "aws_iam_policy_document" "search_services_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:search-services:search-services-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "search_services" {
  name               = "${local.name}-search-services-irsa"
  assume_role_policy = data.aws_iam_policy_document.search_services_assume.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "search_services_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      aws_secretsmanager_secret.aurora.arn,
      aws_secretsmanager_secret.rds.arn,
    ]
  }
}

resource "aws_iam_role_policy" "search_services" {
  name   = "${local.name}-search-services-policy"
  role   = aws_iam_role.search_services.id
  policy = data.aws_iam_policy_document.search_services_policy.json
}
