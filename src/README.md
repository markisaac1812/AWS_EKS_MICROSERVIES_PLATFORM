# SAA Manara - AWS EKS Microservices Platform (Terraform)

Production-grade Terraform for the architecture shown in the diagram:
an EKS cluster running seven microservices split across three node
groups, backed by a database-per-service pattern (DynamoDB), an S3
media store, Aurora + RDS for search/locations, Kafka (MSK) event
streaming, an ElastiCache Redis cluster, and a Lambda-based
notifications service using the outbox/idempotency pattern.

## Architecture mapping

| Diagram element                          | Terraform resource(s)                                   |
|-------------------------------------------|-----------------------------------------------------------|
| VPC                                       | `module.vpc` (vpc.tf)                                      |
| Public subnet + NAT gateway               | `module.vpc` (`public_subnets`, NAT GWs) (vpc.tf)          |
| Private subnet (node groups)              | `module.vpc` (`private_subnets`) (vpc.tf)                  |
| Private subnet (databases)                | `module.vpc` (`database_subnets`) (vpc.tf)                |
| VPC Endpoint                              | `aws_vpc_endpoint.*` (vpc_endpoints.tf)                    |
| EKS                                       | `module.eks` (eks.tf)                                      |
| Network Load Balancer                     | `aws_lb.main` + AWS Load Balancer Controller (load_balancer.tf, eks_addons.tf) |
| Node group (auth, users, reservations)    | `core-services` managed node group (eks.tf)                |
| Node group (media, payment, sessions)     | `commerce-services` managed node group (eks.tf)            |
| Node group (search, locations)            | `search-services` managed node group (eks.tf)               |
| auth db / user db / reservations db       | DynamoDB tables (dynamodb.tf)                               |
| media db / payment db / session db        | DynamoDB tables (dynamodb.tf)                               |
| S3                                         | `aws_s3_bucket.media` (s3.tf)                               |
| Amazon Aurora (search)                    | `aws_rds_cluster.search` (aurora.tf)                         |
| Amazon RDS (locations)                    | `aws_db_instance.locations` (rds.tf)                         |
| Kafka                                      | `aws_msk_cluster.kafka` (msk.tf)                             |
| Redis cluster                              | `aws_elasticache_replication_group.redis` (elasticache.tf)   |
| notifications service                      | `aws_lambda_function.notifications` (lambda.tf)              |
| notification db (outbox/idempotency)       | DynamoDB table with TTL (dynamodb.tf)                        |

## File layout

```
src/
  versions.tf              Terraform + provider version constraints, backend
  providers.tf              AWS/Kubernetes/Helm provider configuration
  variables.tf               Input variables
  locals.tf                   Naming, tags, DynamoDB table map
  data.tf                      Data sources (AZs)
  vpc.tf                        VPC, subnets, NAT gateways
  vpc_endpoints.tf              Gateway/interface VPC endpoints
  security_groups.tf            SGs for RDS, Aurora, MSK, Redis, Lambda
  eks.tf                          EKS cluster + 3 managed node groups
  eks_addons.tf                    AWS Load Balancer Controller, Cluster Autoscaler (Helm)
  irsa.tf                           IAM roles for service accounts (per workload group)
  load_balancer.tf                  Network Load Balancer + target groups/listeners
  dynamodb.tf                        DynamoDB tables (per microservice)
  s3.tf                                Media S3 bucket
  rds.tf                                RDS instance (locations service)
  aurora.tf                             Aurora cluster (search service)
  msk.tf                                  Amazon MSK (Kafka) cluster
  elasticache.tf                          ElastiCache Redis replication group
  lambda.tf                                 Notifications Lambda + MSK event source mapping
  lambda_src/notifications/index.py           Placeholder Lambda handler
  secrets.tf                                    Secrets Manager entries for DB credentials
  outputs.tf                                      Output values
  policies/aws-load-balancer-controller-policy.json  IAM policy for the LB controller
  terraform.tfvars.example                             Example variable values
```

## Usage

```bash
cd src
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars, and versions.tf's backend block, for your account/region

terraform init
terraform plan
terraform apply
```

After the cluster is up, configure `kubectl`:

```bash
aws eks update-kubeconfig --name <eks_cluster_name output> --region <aws_region>
```

Each microservice's Kubernetes ServiceAccount should be annotated with
the matching IRSA role ARN from the `irsa_role_arns` output, e.g.:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: core-services-sa
  namespace: core-services
  annotations:
    eks.amazonaws.com/role-arn: <irsa_role_arns.core_services>
```

## Notes / production considerations

- **Remote state**: fill in the `backend "s3"` block in `versions.tf`
  (a pre-existing state bucket + DynamoDB lock table is assumed).
- **NAT vs. VPC endpoints**: interface/gateway endpoints keep ECR, S3,
  DynamoDB, STS, Secrets Manager and CloudWatch Logs traffic off the
  public internet; NAT gateways remain for Docker Hub and other public
  registries/traffic, matching the diagram's "NAT gateway to pull
  images from ECR or Docker Hub" note.
- **NLB target registration**: real target registration for Kubernetes
  Services/Ingress is handled dynamically by the AWS Load Balancer
  Controller (installed via Helm in `eks_addons.tf`); the static
  `aws_lb` resource is provided for a pre-provisioned, shared ingress
  scenario.
- **Secrets**: RDS/Aurora/Redis credentials are generated with
  `random_password` and stored in Secrets Manager rather than in
  Terraform variables/state in plaintext-adjacent form.
- **Lambda deployment package**: `lambda_src/notifications/index.py` is
  a placeholder; replace with the real notifications service code
  before deploying to production.
- **Multi-AZ / HA**: NAT gateways, Aurora, RDS, MSK, and Redis are all
  configured for multi-AZ deployment by default; adjust
  `single_nat_gateway` and instance counts for lower-cost, non-prod
  environments.
