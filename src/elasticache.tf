############################################
# ElastiCache - Redis cluster
############################################

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${local.name}-redis-subnet-group"
  subnet_ids = module.vpc.database_subnets

  tags = local.common_tags
}

resource "random_password" "redis_auth" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "redis_auth" {
  name       = "${local.name}/elasticache/redis-auth-token"
  kms_key_id = aws_kms_key.dynamodb.arn

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id     = aws_secretsmanager_secret.redis_auth.id
  secret_string = random_password.redis_auth.result
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${local.name}-redis"
  description           = "Shared Redis cluster for caching and session lookups"

  engine         = "redis"
  engine_version = var.redis_engine_version
  node_type      = var.redis_node_type

  num_cache_clusters = var.redis_num_cache_clusters
  port               = 6379

  subnet_group_name = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  automatic_failover_enabled = true
  multi_az_enabled           = true

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth.result

  snapshot_retention_limit = 5
  snapshot_window          = "03:00-05:00"
  maintenance_window       = "mon:05:30-mon:06:30"

  tags = merge(local.common_tags, { Name = "${local.name}-redis" })
}
