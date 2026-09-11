############################################
# DynamoDB - one table per microservice (database-per-service pattern)
# auth, users, reservations, media, payment, sessions, notification
############################################

resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for DynamoDB table encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(local.common_tags, { Name = "${local.name}-dynamodb-kms" })
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/${local.name}-dynamodb"
  target_key_id = aws_kms_key.dynamodb.key_id
}

resource "aws_dynamodb_table" "tables" {
  for_each = local.dynamodb_tables

  name         = each.value
  billing_mode = var.dynamodb_billing_mode
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }

  # The notification table doubles as an outbox/idempotency store
  # (see lambda.tf) - expired records are pruned automatically.
  dynamic "ttl" {
    for_each = each.key == "notification" ? [1] : []
    content {
      attribute_name = "expires_at"
      enabled        = true
    }
  }

  tags = merge(local.common_tags, {
    Name    = each.value
    Service = each.key
  })
}
