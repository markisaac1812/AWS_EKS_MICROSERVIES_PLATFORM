############################################
# Security groups for the data tier and shared services.
# EKS cluster/node security groups are created by the eks module itself
# (module.eks.node_security_group_id / module.eks.cluster_security_group_id).
############################################

# ---- RDS (locations service) ----
resource "aws_security_group" "rds" {
  name        = "${local.name}-rds-sg"
  description = "Allow Postgres access from EKS nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Postgres from EKS nodes"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups  = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name}-rds-sg" })
}

# ---- Aurora (search service) ----
resource "aws_security_group" "aurora" {
  name        = "${local.name}-aurora-sg"
  description = "Allow Postgres access from EKS nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Postgres from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name}-aurora-sg" })
}

# ---- Amazon MSK (Kafka) ----
resource "aws_security_group" "msk" {
  name        = "${local.name}-msk-sg"
  description = "Allow Kafka access from EKS nodes and the notifications Lambda"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Kafka TLS from EKS nodes"
    from_port       = 9094
    to_port         = 9094
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id, aws_security_group.lambda.id]
  }

  ingress {
    description     = "Kafka plaintext from EKS nodes"
    from_port       = 9092
    to_port         = 9092
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id, aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name}-msk-sg" })
}

# ---- ElastiCache Redis ----
resource "aws_security_group" "redis" {
  name        = "${local.name}-redis-sg"
  description = "Allow Redis access from EKS nodes and the notifications Lambda"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Redis from EKS nodes"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id, aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name}-redis-sg" })
}

# ---- Notifications Lambda (runs inside the VPC to reach MSK/Redis) ----
resource "aws_security_group" "lambda" {
  name        = "${local.name}-notifications-lambda-sg"
  description = "Security group for the notifications Lambda function"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name}-notifications-lambda-sg" })
}
