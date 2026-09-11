############################################
# EKS Cluster + managed node groups
#
# Three node groups mirror the diagram's workload grouping:
#   core-services     -> auth, users, reservations pods
#   commerce-services  -> media, payment, sessions pods
#   search-services    -> search, locations pods
############################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    subnet_ids     = module.vpc.private_subnets
    disk_size      = 50
    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    core-services = {
      name           = "${local.name}-core-services"
      instance_types = var.core_node_group.instance_types
      capacity_type  = var.core_node_group.capacity_type
      min_size       = var.core_node_group.min_size
      max_size       = var.core_node_group.max_size
      desired_size   = var.core_node_group.desired_size

      labels = {
        workload-group = "core-services"
      }

      tags = { NodeGroup = "core-services" }
    }

    commerce-services = {
      name           = "${local.name}-commerce-services"
      instance_types = var.commerce_node_group.instance_types
      capacity_type  = var.commerce_node_group.capacity_type
      min_size       = var.commerce_node_group.min_size
      max_size       = var.commerce_node_group.max_size
      desired_size   = var.commerce_node_group.desired_size

      labels = {
        workload-group = "commerce-services"
      }

      tags = { NodeGroup = "commerce-services" }
    }

    search-services = {
      name           = "${local.name}-search-services"
      instance_types = var.search_node_group.instance_types
      capacity_type  = var.search_node_group.capacity_type
      min_size       = var.search_node_group.min_size
      max_size       = var.search_node_group.max_size
      desired_size   = var.search_node_group.desired_size

      labels = {
        workload-group = "search-services"
      }

      tags = { NodeGroup = "search-services" }
    }
  }

  # Allow node groups to reach the data-tier security groups.
  node_security_group_additional_rules = {
    egress_all = {
      description = "Allow all egress from nodes"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = local.common_tags
}
