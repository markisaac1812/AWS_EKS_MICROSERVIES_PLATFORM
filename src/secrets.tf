############################################
# Secrets Manager - database credentials
############################################

resource "random_password" "rds_master" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "rds" {
  name       = "${local.name}/rds/locations-service"
  kms_key_id = aws_kms_key.dynamodb.arn

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode({
    username = "locations_admin"
    password = random_password.rds_master.result
    engine   = var.rds_engine
    host     = aws_db_instance.locations.address
    port     = aws_db_instance.locations.port
    dbname   = aws_db_instance.locations.db_name
  })
}

resource "random_password" "aurora_master" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "aurora" {
  name       = "${local.name}/aurora/search-service"
  kms_key_id = aws_kms_key.dynamodb.arn

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "aurora" {
  secret_id = aws_secretsmanager_secret.aurora.id
  secret_string = jsonencode({
    username = "search_admin"
    password = random_password.aurora_master.result
    engine   = var.aurora_engine
    host     = aws_rds_cluster.search.endpoint
    port     = aws_rds_cluster.search.port
    dbname   = aws_rds_cluster.search.database_name
  })
}
