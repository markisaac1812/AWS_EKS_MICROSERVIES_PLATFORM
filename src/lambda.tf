############################################
# Notifications service (Lambda)
#
# Consumes events from Amazon MSK (Kafka), and uses the notification
# DynamoDB table as an outbox/idempotency store so the same
# notification is never sent twice.
############################################

data "archive_file" "notifications" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src/notifications"
  output_path = "${path.module}/build/notifications.zip"
}

data "aws_iam_policy_document" "notifications_lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "notifications_lambda" {
  name               = "${local.name}-notifications-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.notifications_lambda_assume.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "notifications_lambda_vpc" {
  role       = aws_iam_role.notifications_lambda.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "notifications_lambda_msk" {
  role       = aws_iam_role.notifications_lambda.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaMSKExecutionRole"
}

data "aws_iam_policy_document" "notifications_lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
    ]
    resources = [aws_dynamodb_table.tables["notification"].arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "notifications_lambda" {
  name   = "${local.name}-notifications-lambda-policy"
  role   = aws_iam_role.notifications_lambda.id
  policy = data.aws_iam_policy_document.notifications_lambda_policy.json
}

resource "aws_cloudwatch_log_group" "notifications_lambda" {
  name              = "/aws/lambda/${local.name}-notifications"
  retention_in_days = 30

  tags = local.common_tags
}

resource "aws_lambda_function" "notifications" {
  function_name = "${local.name}-notifications"
  role          = aws_iam_role.notifications_lambda.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  memory_size   = var.notifications_lambda_memory
  timeout       = var.notifications_lambda_timeout

  filename         = data.archive_file.notifications.output_path
  source_code_hash = data.archive_file.notifications.output_base64sha256

  vpc_config {
    subnet_ids         = module.vpc.database_subnets
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      NOTIFICATION_TABLE_NAME = aws_dynamodb_table.tables["notification"].name
      REDIS_ENDPOINT          = aws_elasticache_replication_group.redis.primary_endpoint_address
      SES_SENDER_EMAIL        = var.ses_sender_email
    }
  }

  depends_on = [aws_cloudwatch_log_group.notifications_lambda]

  tags = merge(local.common_tags, { Name = "${local.name}-notifications" })
}

# Note: source_access_configuration (VPC_SUBNET / VPC_SECURITY_GROUP) is
# only needed for self-managed Kafka event sources. For Amazon MSK,
# Lambda automatically uses the cluster's own VPC/subnet/security-group
# configuration, so no explicit VPC wiring is required here.
resource "aws_lambda_event_source_mapping" "notifications_msk" {
  event_source_arn  = aws_msk_cluster.kafka.arn
  function_name     = aws_lambda_function.notifications.arn
  topics            = ["notifications"]
  starting_position = "LATEST"

  depends_on = [aws_iam_role_policy_attachment.notifications_lambda_msk]
}
