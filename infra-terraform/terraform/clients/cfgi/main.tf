# =============================================================================
# CFGI CLIENT INFRASTRUCTURE - FOUNDATION CONFIGURATION
# =============================================================================
#
# This file contains the foundation infrastructure for CFGI client deployment:
#   - Local variables configuration
#   - VPC and networking (CFGI-002)
#   - Security groups (CFGI-003)
#   - IAM roles (CFGI-004)
#
# Product-specific resources are defined in separate files:
#   - kimball.tf: Kimball product infrastructure
#   - monza.tf: Monza product infrastructure
#
# =============================================================================

# =============================================================================
# LOCAL VARIABLES
# =============================================================================

locals {
  # AWS Configuration
  aws_region   = "us-east-2"
  environment  = "prod" # Clients deploy production workloads
  project_name = "cfgi" # Results in resource names like: cfgi-prod-vpc
  client_name  = "CFGI"

  # Network Configuration (mirrors kainam-dev-vpc structure)
  vpc_cidr             = "10.10.0.0/16"
  availability_zones   = ["us-east-2a", "us-east-2b"]
  public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnet_cidrs = ["10.10.101.0/24", "10.10.102.0/24"]

  # Security Configuration
  trusted_ip_ranges = ["0.0.0.0/0"] # Open SSH access per client requirement

  # Kimball Product Configuration
  kimball_domain = "kimball-cfgi.kainam.app"
  github_org     = "kainamAI"

  # Common Tags (applied to all resources)
  common_tags = {
    Client      = local.client_name
    Project     = local.project_name
    Environment = local.environment
    Owner       = "Kainam DevOps"
    ManagedBy   = "Terraform"
    Purpose     = "Client Production Infrastructure"
    IaC         = "true"
  }
}

# =============================================================================
# FOUNDATION INFRASTRUCTURE MODULES
# =============================================================================
# 
# These modules will be added in subsequent tasks:
#   - CFGI-002: VPC Module (networking infrastructure)
#   - CFGI-003: Security Groups Module (network security)
#   - CFGI-004: IAM Roles Module (identity and access management)
#
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Module (CFGI-002)
# -----------------------------------------------------------------------------
# Deploys:
#   - VPC with CIDR 10.10.0.0/16
#   - Public and private subnets across 2 AZs
#   - Internet Gateway and NAT Gateway
#   - Route tables and associations
#
module "vpc" {
  source = "../../modules/vpc"

  environment          = local.environment
  project_name         = local.project_name
  vpc_cidr             = local.vpc_cidr
  availability_zones   = local.availability_zones
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  common_tags          = local.common_tags
}

# -----------------------------------------------------------------------------
# Security Groups Module (CFGI-003)
# -----------------------------------------------------------------------------
# Will deploy:
#   - ALB security group (HTTPS from internet)
#   - Web security group (SSH from trusted IPs)
#   - Database security group (PostgreSQL from web tier)
#
# module "security_groups" {
#   source = "../../modules/security-groups"
#   
#   environment       = local.environment
#   project_name      = local.project_name
#   vpc_id            = module.vpc.vpc_id
#   vpc_cidr_block    = module.vpc.vpc_cidr_block
#   trusted_ip_ranges = local.trusted_ip_ranges
#   common_tags       = local.common_tags
# }

# -----------------------------------------------------------------------------
# IAM Roles Module (CFGI-004)
# -----------------------------------------------------------------------------
# Deploys:
#   - App Runner access role (ECR image pull)
#   - App Runner instance role (CloudWatch, VPC access)
#   - EC2 instance role for Monza (ECR, SSM, CloudWatch)
#
# Note: GitHub Actions OIDC is disabled - not using GitHub Actions for now
#
module "iam_roles" {
  source = "../../modules/iam-roles"

  environment  = local.environment
  project_name = local.project_name
  service_name = "kimball"

  # GitHub Actions OIDC Configuration (DISABLED - not using for now)
  create_github_oidc_provider = false
  create_github_oidc_role     = false
  github_org                  = ""
  github_repositories         = []
  github_branches             = []
  ecr_repository_arns         = [] # Will be populated after ECR creation (CFGI-005)

  # App Runner Configuration
  create_app_runner_access_role   = true
  create_app_runner_instance_role = true

  # EC2 Configuration (for Monza)
  create_ec2_instance_role = true
  create_ec2_worker_role   = false # Not needed for Monza

  common_tags = local.common_tags
}
