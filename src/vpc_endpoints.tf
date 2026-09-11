############################################
# VPC Endpoints
# Keeps node -> AWS-service traffic (ECR pulls, S3, DynamoDB, Secrets
# Manager, CloudWatch Logs, STS for IRSA) off the public internet where
# possible. NAT gateways remain for Docker Hub / other public registries.
############################################

resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.name}-vpce-sg"
  description = "Allow HTTPS from within the VPC to interface endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name}-vpce-sg" })
}

locals {
  interface_endpoints = [
    "ecr.api",
    "ecr.dkr",
    "sts",
    "logs",
    "secretsmanager",
    "ec2",
    "elasticloadbalancing",
  ]
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(local.interface_endpoints)

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, { Name = "${local.name}-vpce-${each.value}" })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = concat(
    module.vpc.private_route_table_ids,
    module.vpc.database_route_table_ids
  )

  tags = merge(local.common_tags, { Name = "${local.name}-vpce-s3" })
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids = concat(
    module.vpc.private_route_table_ids,
    module.vpc.database_route_table_ids
  )

  tags = merge(local.common_tags, { Name = "${local.name}-vpce-dynamodb" })
}
