locals {
  name = "${var.project_name}-${var.environment}"

  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  # Microservice -> DynamoDB table map (database-per-service pattern).
  dynamodb_tables = {
    auth         = "${local.name}-auth-db"
    users        = "${local.name}-users-db"
    reservations = "${local.name}-reservations-db"
    media        = "${local.name}-media-db"
    payment      = "${local.name}-payment-db"
    sessions     = "${local.name}-session-db"
    notification = "${local.name}-notification-db"
  }

  cluster_name = "${local.name}-eks"
}
