############################################
# Amazon Aurora - search service
############################################

resource "aws_rds_cluster" "search" {
  cluster_identifier = "${local.name}-search-aurora"
  engine             = var.aurora_engine
  engine_version     = var.aurora_engine_version
  engine_mode        = "provisioned"

  database_name   = "search"
  master_username = "search_admin"
  master_password = random_password.aurora_master.result
  port            = 5432

  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.aurora.id]

  storage_encrypted = true
  kms_key_id        = aws_kms_key.dynamodb.arn

  backup_retention_period   = 7
  preferred_backup_window   = "03:00-04:00"
  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.name}-search-aurora-final"
  copy_tags_to_snapshot     = true

  tags = merge(local.common_tags, { Name = "${local.name}-search-aurora" })
}

resource "aws_rds_cluster_instance" "search" {
  count = var.aurora_instance_count

  identifier         = "${local.name}-search-aurora-${count.index}"
  cluster_identifier = aws_rds_cluster.search.id
  engine             = aws_rds_cluster.search.engine
  engine_version     = aws_rds_cluster.search.engine_version
  instance_class     = var.aurora_instance_class

  performance_insights_enabled = true

  tags = merge(local.common_tags, { Name = "${local.name}-search-aurora-${count.index}" })
}
