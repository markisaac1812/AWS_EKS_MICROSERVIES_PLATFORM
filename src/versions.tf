terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Recommended for production: store state remotely with locking.
  # Configure via `terraform init -backend-config=...` or fill in directly.
  backend "s3" {
    # bucket         = "saa-manara-terraform-state"
    # key            = "eks-platform/terraform.tfstate"
    # region         = "us-east-1"
    # dynamodb_table = "saa-manara-terraform-locks"
    # encrypt        = true
  }
}
