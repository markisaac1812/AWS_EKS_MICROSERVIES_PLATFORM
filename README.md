# SAA Manara – Platform Architecture

![Architecture diagram](docs/architecture-diagram.png)

The Terraform that actually provisions all of this lives in [`src/`](src/). This file is the "read this first" explanation — what the diagram is showing, the reasoning behind each piece, and the tradeoffs I made along the way.

## The big picture

Everything sits inside a single VPC. In the middle of it is an EKS cluster, and instead of throwing every microservice into one big node pool, I split the workloads into three node groups based on how they're used and how they scale:

- **Group 1** – `auth`, `users`, `reservations`. These are the "core" services that basically everything else depends on. They're chatty but not resource-heavy, so they share a node group.
- **Group 2** – `media`, `payment`, `sessions`. These get bursty traffic (uploads, checkout spikes) so I wanted them isolated from the core services — if payment traffic spikes and that node group scales up, it shouldn't starve auth.
- **Group 3** – `search` and `locations`. These two talk to relational databases (Aurora and RDS) instead of DynamoDB, so I kept them together and separate from everything else — different scaling pattern, different blast radius if something goes wrong with a query.

A Network Load Balancer sits in front of the cluster and routes traffic down into whichever service needs it. I went with an NLB instead of an ALB because most of this traffic is plain TCP between internal services and I didn't need layer-7 routing rules at the edge — that logic lives inside the cluster with an ingress controller instead.

## Why "one database per service"

You'll notice `auth`, `users`, `reservations`, `media`, `payment`, and `sessions` each get their own database. That's on purpose — it's the classic database-per-service pattern. I picked DynamoDB for these because:

- Each service owns its own data and its own schema. Nobody has to ask permission to change a table because someone else's service also reads from it.
- These are mostly key-value / lookup-style access patterns (get a user by ID, get a reservation by ID), which is exactly what DynamoDB is good at.
- Pay-per-request billing means I'm not paying for idle capacity on services that don't get constant traffic.

`search` and `locations` are the odd ones out — they need actual relational queries (joins, geo lookups, full-text-ish search), so they sit on Aurora and RDS Postgres instead of DynamoDB. Aurora backs `search` because it needs to scale reads independently of writes (Aurora replicas), and `locations` runs on plain RDS since its read/write pattern is simpler and doesn't justify Aurora's extra cost.

Media files themselves (images, video, whatever gets uploaded) don't belong in a database at all, so those go straight to S3, with a small DynamoDB table (`media db`) just tracking metadata about each object — owner, upload time, status, etc.

## Kafka, the notification service, and why there's a "notification db"

This is the part of the diagram that looks over-engineered until you think about what it's actually solving: **making sure a customer never gets the same email twice.**

Here's the flow: services publish events onto Kafka (Amazon MSK) — "reservation confirmed," "payment failed," whatever. A Lambda function (`notifications service`) picks those events up and is responsible for sending them out. The problem with any event-driven system is that messages can get delivered more than once — that's just a fact of life with Kafka consumers, retries, and Lambda's at-least-once delivery guarantee.

So before the Lambda actually sends anything, it checks the `notification db` (DynamoDB) to see if that event ID has already been processed. If it has, it just drops the message. If not, it sends the notification and writes a record so it never fires again for that same event. That's the outbox / idempotency pattern in the diagram's own words — it's not there to store notification content long-term, it's there purely so duplicate events don't turn into duplicate emails.

## Redis cluster

Sitting off to the side is a Redis cluster (ElastiCache), shared across services. This isn't tied to one microservice — it's there for things like session lookups and caching hot data so services aren't hammering DynamoDB/RDS/Aurora for the same reads over and over. Since it's shared infrastructure, it gets its own subnet and security group rather than living inside any one node group.

## Subnets, NAT gateways, and endpoints — the boring but important part

Every node group lives in a **private subnet**. None of the worker nodes have a public IP, and none of the databases do either. The only things that touch a public subnet are the NAT gateways and the load balancer.

The NAT gateways exist for one reason mainly: pulling container images. Nodes need to reach ECR (or Docker Hub, if that's where an image lives) to pull images when pods start up, and that means outbound internet access. Rather than route *all* AWS API traffic through the NAT gateway, I added VPC endpoints for the services nodes talk to constantly — S3, DynamoDB, ECR, STS, Secrets Manager, CloudWatch Logs. That traffic goes over AWS's private network instead of out through NAT, which is both cheaper (NAT gateways charge per GB) and more secure (it never touches the public internet at all).

## How pods actually get permission to touch AWS resources

I didn't want to give every node in the cluster a single IAM role with access to everything — that means a bug in one service could touch another service's database. Instead, each node group's service account is mapped to its own IAM role via IRSA (IAM Roles for Service Accounts):

- The core-services group can only read/write `auth`, `users`, and `reservations` tables.
- The commerce-services group can only touch `media`, `payment`, `sessions`, and the S3 media bucket.
- The search-services group only gets permission to pull credentials for Aurora/RDS out of Secrets Manager — it never touches DynamoDB at all.

That way if one service's pod gets compromised or misconfigured, the blast radius is limited to that service's own data.

## What I'd call out if someone asked "what would you change with more time"

- Right now the NLB target groups are static placeholders in Terraform — in a real rollout, target registration should be handled dynamically by the AWS Load Balancer Controller based on Kubernetes Service/Ingress objects, since pod IPs change constantly.
- Kafka topic-level ACLs and schema registry aren't modeled here — worth adding once there's more than one team producing events.
- I'd add autoscaling policies tuned per node group instead of one generic Cluster Autoscaler config, since the three groups have very different traffic shapes.

## Where the actual infrastructure code lives

All of this is provisioned with Terraform under [`src/`](src/) — VPC, EKS, node groups, DynamoDB tables, S3, Aurora, RDS, MSK, ElastiCache, the notifications Lambda, IAM/IRSA roles, and the supporting security groups. See `src/README.md` for the file-by-file breakdown and how to run it.
