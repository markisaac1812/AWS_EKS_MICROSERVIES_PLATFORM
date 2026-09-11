############################################
# Global
############################################

variable "aws_region" {
  description = "AWS region to deploy the platform into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project name used as a prefix for resource names."
  type        = string
  default     = "saa-manara"
}

variable "environment" {
  description = "Deployment environment name (e.g. production, staging)."
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Extra tags applied to every resource."
  type        = map(string)
  default     = {}
}

############################################
# Networking
############################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to spread the platform across."
  type        = number
  default     = 3
}

variable "single_nat_gateway" {
  description = "If true, use a single NAT Gateway for all AZs (cheaper, less resilient). Production should set this to false."
  type        = bool
  default     = false
}

############################################
# EKS
############################################

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.29"
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS public API endpoint is enabled."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Node group 1: auth, users, reservations
variable "core_node_group" {
  description = "Config for the core-services node group (auth, users, reservations)."
  type = object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    capacity_type  = string
  })
  default = {
    instance_types = ["m6i.large"]
    min_size       = 2
    max_size       = 5
    desired_size   = 2
    capacity_type  = "ON_DEMAND"
  }
}

# Node group 2: media, payment, sessions
variable "commerce_node_group" {
  description = "Config for the commerce-services node group (media, payment, sessions)."
  type = object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    capacity_type  = string
  })
  default = {
    instance_types = ["m6i.large"]
    min_size       = 2
    max_size       = 6
    desired_size   = 2
    capacity_type  = "ON_DEMAND"
  }
}

# Node group 3: search, locations
variable "search_node_group" {
  description = "Config for the search-services node group (search, locations)."
  type = object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    capacity_type  = string
  })
  default = {
    instance_types = ["m6i.large"]
    min_size       = 2
    max_size       = 5
    desired_size   = 2
    capacity_type  = "ON_DEMAND"
  }
}

############################################
# Databases
############################################

variable "dynamodb_billing_mode" {
  description = "Billing mode for all DynamoDB tables."
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "rds_engine" {
  description = "Engine used by the Amazon RDS instance (locations service)."
  type        = string
  default     = "postgres"
}

variable "rds_engine_version" {
  description = "Engine version for the Amazon RDS instance."
  type        = string
  default     = "16.3"
}

variable "rds_instance_class" {
  description = "Instance class for the Amazon RDS instance."
  type        = string
  default     = "db.t3.medium"
}

variable "rds_allocated_storage" {
  description = "Allocated storage (GiB) for the Amazon RDS instance."
  type        = number
  default     = 50
}

variable "rds_multi_az" {
  description = "Whether the RDS instance is Multi-AZ."
  type        = bool
  default     = true
}

variable "aurora_engine" {
  description = "Aurora engine used by the search service database."
  type        = string
  default     = "aurora-postgresql"
}

variable "aurora_engine_version" {
  description = "Aurora engine version."
  type        = string
  default     = "16.2"
}

variable "aurora_instance_class" {
  description = "Instance class for Aurora cluster instances."
  type        = string
  default     = "db.r6g.large"
}

variable "aurora_instance_count" {
  description = "Number of instances (1 writer + N readers) in the Aurora cluster."
  type        = number
  default     = 2
}

############################################
# Kafka (Amazon MSK)
############################################

variable "kafka_version" {
  description = "Apache Kafka version for the MSK cluster."
  type        = string
  default     = "3.6.0"
}

variable "kafka_broker_instance_type" {
  description = "Instance type for MSK broker nodes."
  type        = string
  default     = "kafka.m5.large"
}

variable "kafka_ebs_volume_size" {
  description = "EBS volume size (GiB) per broker."
  type        = number
  default     = 100
}

############################################
# ElastiCache (Redis)
############################################

variable "redis_node_type" {
  description = "Node type for the ElastiCache Redis cluster."
  type        = string
  default     = "cache.r6g.large"
}

variable "redis_num_cache_clusters" {
  description = "Number of nodes (primary + replicas) in the Redis replication group."
  type        = number
  default     = 3
}

variable "redis_engine_version" {
  description = "Redis engine version."
  type        = string
  default     = "7.1"
}

############################################
# Lambda (notifications service)
############################################

variable "notifications_lambda_memory" {
  description = "Memory (MB) allocated to the notifications Lambda function."
  type        = number
  default     = 256
}

variable "notifications_lambda_timeout" {
  description = "Timeout (seconds) for the notifications Lambda function."
  type        = number
  default     = 30
}

variable "ses_sender_email" {
  description = "Verified SES sender address used by the notifications service."
  type        = string
  default     = "no-reply@example.com"
}
