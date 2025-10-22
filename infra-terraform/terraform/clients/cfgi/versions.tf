# =============================================================================
# TERRAFORM AND PROVIDER VERSION REQUIREMENTS
# =============================================================================
# 
# Defines Terraform version constraints and required providers for CFGI client
# deployment. Follows semantic versioning for stability and reproducibility.
#
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# =============================================================================
# AWS PROVIDER CONFIGURATION
# =============================================================================
# 
# Configures AWS provider for CFGI client account access via SSO profile.
# All resources will be created in the CFGI AWS account.
#
# Profile Setup:
#   aws sso login --profile cfgi-sso
#
# =============================================================================

provider "aws" {
  region  = "us-east-2"
  profile = "cfgi-sso"

  default_tags {
    tags = {
      Client     = "CFGI"
      ManagedBy  = "Terraform"
      Repository = "kainam-backend"
      IaC        = "true"
    }
  }
}
