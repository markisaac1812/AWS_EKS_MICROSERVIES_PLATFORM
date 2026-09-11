############################################
# Outputs
############################################

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "database_subnet_ids" {
  value = module.vpc.database_subnets
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "eks_node_security_group_id" {
  value = module.eks.node_security_group_id
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer fronting the cluster."
  value       = aws_lb.main.dns_name
}

output "dynamodb_table_names" {
  value = { for k, v in aws_dynamodb_table.tables : k => v.name }
}

output "media_bucket_name" {
  value = aws_s3_bucket.media.bucket
}

output "rds_locations_endpoint" {
  value = aws_db_instance.locations.endpoint
}

output "aurora_search_endpoint" {
  value = aws_rds_cluster.search.endpoint
}

output "aurora_search_reader_endpoint" {
  value = aws_rds_cluster.search.reader_endpoint
}

output "msk_cluster_arn" {
  value = aws_msk_cluster.kafka.arn
}

output "msk_bootstrap_brokers_tls" {
  value = aws_msk_cluster.kafka.bootstrap_brokers_tls
}

output "redis_primary_endpoint" {
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "notifications_lambda_name" {
  value = aws_lambda_function.notifications.function_name
}

output "irsa_role_arns" {
  description = "IAM role ARNs for each workload group's Kubernetes service account."
  value = {
    core_services      = aws_iam_role.core_services.arn
    commerce_services  = aws_iam_role.commerce_services.arn
    search_services    = aws_iam_role.search_services.arn
  }
}
