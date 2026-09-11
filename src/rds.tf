############################################
# Amazon RDS - locations service
############################################

resource "aws_db_instance" "locations" {
  identifier     = "${local.name}-locations-db"
  engine         = var.rds_engine
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class

  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_allocated_storage * 4
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.dynamodb.arn

  db_name  = "locations"
  username = "locations_admin"
  password = random_password.rds_master.result
  port     = 5432

  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                     = var.rds_multi_az
  backup_retention_period      = 7
  backup_window                = "03:00-04:00"
  maintenance_window           = "mon:04:30-mon:05:30"
  deletion_protection          = true
  skip_final_snapshot          = false
  final_snapshot_identifier    = "${local.name}-locations-db-final"
  copy_tags_to_snapshot        = true
  auto_minor_version_upgrade   = true
  performance_insights_enabled = true

  tags = merge(local.common_tags, { Name = "${local.name}-locations-db" })
}
