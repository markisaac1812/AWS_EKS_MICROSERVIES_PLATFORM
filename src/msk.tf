############################################
# Amazon MSK - Kafka cluster
############################################

resource "aws_kms_key" "msk" {
  description             = "KMS key for MSK cluster encryption at rest"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(local.common_tags, { Name = "${local.name}-msk-kms" })
}

resource "aws_cloudwatch_log_group" "msk" {
  name              = "/msk/${local.name}"
  retention_in_days = 30

  tags = local.common_tags
}

resource "aws_msk_configuration" "main" {
  name              = "${local.name}-msk-config"
  kafka_versions    = [var.kafka_version]
  server_properties = <<-PROPERTIES
    auto.create.topics.enable=false
    default.replication.factor=3
    min.insync.replicas=2
    num.partitions=6
  PROPERTIES
}

resource "aws_msk_cluster" "kafka" {
  cluster_name           = "${local.name}-kafka"
  kafka_version          = var.kafka_version
  number_of_broker_nodes = length(module.vpc.database_subnets)

  broker_node_group_info {
    instance_type   = var.kafka_broker_instance_type
    client_subnets  = module.vpc.database_subnets
    security_groups = [aws_security_group.msk.id]

    storage_info {
      ebs_storage_info {
        volume_size = var.kafka_ebs_volume_size
      }
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.main.arn
    revision = aws_msk_configuration.main.latest_revision
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.msk.arn

    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk.name
      }
    }
  }

  enhanced_monitoring = "PER_TOPIC_PER_BROKER"

  tags = merge(local.common_tags, { Name = "${local.name}-kafka" })
}
