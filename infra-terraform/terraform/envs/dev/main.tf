# Local values for dev environment
locals {
  aws_region   = "us-east-2"
  environment  = "dev"
  project_name = "kainam"

  # Dev-specific configuration
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-2a", "us-east-2b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]

  # Security configuration - empty by default for dev (no SSH access)
  # Add your IP ranges here if SSH access is needed: ["x.x.x.x/32"]
  trusted_ip_ranges = []

  # ETL configuration
  etl_availability_zone         = "us-east-2a"
  etl_public_subnet_cidr        = "10.0.3.0/24"
  etl_private_subnet_cidr       = "10.0.103.0/24"
  etl_allow_all_external_access = true # Development mode

  # Authentication ALB configuration
  auth_subdomain = "auth-dev"
  base_domain    = "kainam.app"
  ssl_policy     = "ELBSecurityPolicy-TLS-1-2-2017-01"

  # Keycloak SSH configuration
  keycloak_trusted_ip_ranges = ["189.237.189.127/32"] # Your specific IP for maintenance access

  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    Owner       = "DevOps"
    ManagedBy   = "Terraform"
    Purpose     = "Development"
  }
}

# Data sources for authentication ALB
data "aws_acm_certificate" "wildcard_kainam_app" {
  domain      = "*.kainam.app"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

data "aws_route53_zone" "kainam_app" {
  name         = "kainam.app"
  private_zone = false
}

# VPC Module
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

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  environment       = local.environment
  project_name      = local.project_name
  vpc_id            = module.vpc.vpc_id
  vpc_cidr_block    = module.vpc.vpc_cidr_block
  trusted_ip_ranges = local.trusted_ip_ranges
  common_tags       = local.common_tags
}

# Kimball ETL Networking Module
module "kimball_etl_networking" {
  source = "../../modules/kimball-etl-networking"

  vpc_id                 = module.vpc.vpc_id
  public_route_table_id  = module.vpc.public_route_table_id
  private_route_table_id = module.vpc.private_route_table_id

  environment             = local.environment
  project_name            = local.project_name
  availability_zone       = local.etl_availability_zone
  etl_public_subnet_cidr  = local.etl_public_subnet_cidr
  etl_private_subnet_cidr = local.etl_private_subnet_cidr
  vpc_cidr                = local.vpc_cidr

  trusted_ip_ranges         = local.trusted_ip_ranges
  allow_all_external_access = local.etl_allow_all_external_access

  common_tags = local.common_tags
}

# Secrets Manager Module
module "secrets_manager" {
  source = "../../modules/secrets-manager"

  project_name                = "keystone" # Using keystone for secrets as per specification
  environment                 = local.environment
  rds_username                = var.rds_username
  rds_password                = var.rds_password
  keycloak_username           = var.keycloak_username
  keycloak_password           = var.keycloak_password
  senna_backend_client_secret = var.senna_backend_client_secret
  additional_tags             = local.common_tags
}

# RDS PostgreSQL Module for Keycloak
module "rds" {
  source = "../../modules/rds"

  # Basic Configuration
  environment  = local.environment
  project_name = local.project_name

  # Database Configuration
  db_name                = "kainam_keycloak_rds_pg_dev"
  db_instance_identifier = "keycloak-db"
  db_username            = var.rds_username
  db_password            = var.rds_password

  # Instance Configuration
  db_instance_class    = "db.t4g.micro"
  db_allocated_storage = 20
  db_storage_type      = "gp3"

  # Network Configuration
  vpc_id                         = module.vpc.vpc_id
  private_subnet_ids             = module.vpc.private_subnet_ids
  keycloak_app_security_group_id = module.keycloak_ec2.security_group_id

  # Backup & Maintenance Configuration
  backup_retention_period = 1
  multi_az                = false
  storage_encrypted       = true
  skip_final_snapshot     = true
  deletion_protection     = false
  monitoring_interval     = 0

  common_tags = local.common_tags
}

# Authentication ALB Module
module "auth_alb" {
  source = "../../modules/auth-alb"

  environment       = local.environment
  project_name      = local.project_name
  vpc_id            = module.vpc.vpc_id
  security_group_id = module.security_groups.alb_security_group_id
  public_subnet_ids = module.vpc.public_subnet_ids
  common_tags       = local.common_tags
}

# Target Groups Module
module "target_groups" {
  source = "../../modules/target-groups"

  environment                  = local.environment
  project_name                 = local.project_name
  vpc_id                       = module.vpc.vpc_id
  create_keycloak_target_group = true
  keycloak_target_port         = 8080
  keycloak_health_check_path   = "/realms/master"
  common_tags                  = local.common_tags
}

# ALB Listeners Module
module "alb_listeners" {
  source = "../../modules/alb-listeners"

  environment       = local.environment
  project_name      = local.project_name
  load_balancer_arn = module.auth_alb.alb_arn
  target_group_arn  = module.target_groups.keycloak_target_group_arn
  certificate_arn   = data.aws_acm_certificate.wildcard_kainam_app.arn
  ssl_policy        = local.ssl_policy
  http_port         = 80
  https_port        = 443
  common_tags       = local.common_tags
}

# Route 53 DNS Records Module
module "route53_records" {
  source = "../../modules/route53-records"

  environment  = local.environment
  project_name = local.project_name

  # Authentication ALB DNS Record
  create_auth_dns_record = true
  auth_subdomain         = local.auth_subdomain
  base_domain            = local.base_domain
  alb_dns_name           = module.auth_alb.alb_dns_name
  alb_zone_id            = module.auth_alb.alb_zone_id

  # SENNA App Runner DNS Record - Points to custom domain DNS target
  create_senna_dns_record = true
  senna_subdomain         = "senna-dev"
  senna_app_runner_url    = module.senna_frontend.dns_target

  # SENNA Certificate Validation Records - DISABLED (manually managed)
  create_senna_certificate_validation_records = false
  senna_certificate_validation_records        = []

  # Kainam Platform App Runner DNS Record - Points to custom domain DNS target
  create_kainam_platform_dns_record = true # Enable CNAME record creation for console-dev.kainam.app
  kainam_platform_subdomain         = "console-dev"
  kainam_platform_app_runner_url    = module.kainam_platform_frontend.service_url

  hosted_zone_id         = data.aws_route53_zone.kainam_app.zone_id
  evaluate_target_health = true
  common_tags            = local.common_tags
}

# ECR Module for SENNA
module "ecr" {
  source = "../../modules/ecr"

  environment                = local.environment
  project_name               = local.project_name
  service_name               = "senna"
  create_api_repository      = true
  create_frontend_repository = true
  create_models_repository   = true
  create_keycloak_repository = true
  image_retention_count      = var.ecr_image_retention_count
  enable_image_scan_on_push  = var.ecr_enable_image_scanning
  repository_encryption_type = var.ecr_repository_encryption_type
  github_actions_principals  = var.ecr_github_actions_principals
  common_tags                = local.common_tags
}

# ECR Module for Kainam Platform
module "kainam_platform_ecr" {
  source = "../../modules/ecr"

  environment                = local.environment
  project_name               = local.project_name
  service_name               = "kainam-platform"
  create_api_repository      = true
  create_frontend_repository = true
  create_models_repository   = false # Not needed for Kainam Platform
  create_keycloak_repository = false # Not needed for Kainam Platform
  image_retention_count      = var.ecr_image_retention_count
  enable_image_scan_on_push  = var.ecr_enable_image_scanning
  repository_encryption_type = var.ecr_repository_encryption_type

  # Add existing CodePipeline role for future GitHub Actions integration
  github_actions_principals = [
    "arn:aws:iam::592172380963:role/kainam-dev-codepipeline-role"
  ]

  common_tags = local.common_tags
}

# ElastiCache Module
module "elasticache" {
  source = "../../modules/elasticache"

  environment  = local.environment
  project_name = local.project_name
  service_name = "senna"
  cluster_id   = "senna-redis-elasticache-${local.environment}"
  description  = "ElastiCache Redis for Senna ${title(local.environment)} - Non-cluster mode"

  # Engine configuration
  engine         = "redis"
  engine_version = var.elasticache_engine_version
  node_type      = var.elasticache_node_type
  port           = 6379

  # Cluster configuration (non-cluster mode as per requirements)
  cluster_mode_enabled = false
  num_cache_nodes      = 1

  # High availability (disabled as per requirements)
  automatic_failover_enabled = false
  multi_az_enabled           = false

  # Network configuration
  vpc_id     = module.vpc.vpc_id
  subnet_ids = var.elasticache_subnet_ids

  # Security configuration
  at_rest_encryption_enabled = var.elasticache_at_rest_encryption_enabled
  transit_encryption_enabled = var.elasticache_transit_encryption_enabled
  auth_token                 = var.elasticache_auth_token

  # Maintenance configuration
  maintenance_window         = var.elasticache_maintenance_window
  apply_immediately          = var.elasticache_apply_immediately
  auto_minor_version_upgrade = var.elasticache_auto_minor_version_upgrade

  # Backup configuration
  snapshot_retention_limit  = var.elasticache_snapshot_retention_limit
  snapshot_window           = var.elasticache_snapshot_window
  final_snapshot_identifier = var.elasticache_final_snapshot_identifier

  # Parameter group configuration
  create_parameter_group = true
  parameter_group_family = var.elasticache_parameter_group_family
  parameters             = var.elasticache_parameters

  common_tags = local.common_tags
}

# IAM Roles Module
module "iam_roles" {
  source = "../../modules/iam-roles"

  environment  = local.environment
  project_name = local.project_name
  service_name = "senna"

  # GitHub Actions OIDC configuration
  create_github_oidc_provider = var.iam_create_github_oidc_provider
  create_github_oidc_role     = var.iam_create_github_oidc_role
  github_org                  = var.iam_github_org
  github_repositories         = var.iam_github_repositories
  github_branches             = var.iam_github_branches
  ecr_repository_arns         = values(module.ecr.repository_arns)

  # App Runner configuration
  create_app_runner_access_role   = var.iam_create_app_runner_access_role
  create_app_runner_instance_role = var.iam_create_app_runner_instance_role
  app_runner_additional_policies  = var.iam_app_runner_additional_policies

  # EC2 configuration
  create_ec2_instance_role = var.iam_create_ec2_instance_role
  create_ec2_worker_role   = var.iam_create_ec2_worker_role
  ec2_additional_policies  = var.iam_ec2_additional_policies

  # Resource ARNs for permissions
  secrets_manager_secret_arns = var.iam_secrets_manager_secret_arns
  elasticache_cluster_arn     = module.elasticache.cluster_arn

  common_tags = local.common_tags
}

# CodePipeline Module
module "codepipeline" {
  source = "../../modules/codepipeline"

  environment  = local.environment
  project_name = local.project_name
  service_name = "senna"

  # Pipeline Configuration
  create_frontend_pipeline = var.codepipeline_create_frontend_pipeline
  create_api_pipeline      = var.codepipeline_create_api_pipeline
  create_models_pipeline   = var.codepipeline_create_models_pipeline
  create_keycloak_pipeline = var.codepipeline_create_keycloak_pipeline

  # Kainam Platform Pipeline Configuration
  create_kainam_platform_api_pipeline      = var.codepipeline_create_kainam_platform_api_pipeline
  create_kainam_platform_frontend_pipeline = var.codepipeline_create_kainam_platform_frontend_pipeline

  source_branch = var.codepipeline_source_branch
  build_timeout = var.codepipeline_build_timeout

  # ECR Configuration
  ecr_repository_urls = module.ecr.repository_urls
  ecr_registry_id     = module.ecr.ecr_registry_id

  # Kainam Platform ECR Configuration
  kainam_platform_ecr_repository_urls = module.kainam_platform_ecr.repository_urls

  common_tags = local.common_tags
}

# ===================================
# SENNA API App Runner Service
# ===================================

module "senna_api" {
  source = "../../modules/app-runner"

  # Basic Configuration
  project_name = local.project_name
  environment  = local.environment
  service_name = "senna-api"

  # ECR Configuration
  ecr_repository_url = module.ecr.repository_urls.api
  image_tag          = "latest"

  # App Configuration
  port   = "8080"
  cpu    = "1024" # 1 vCPU
  memory = "2048" # 2 GB

  # Environment Variables (from your configuration)
  environment_variables = {
    AWS_ACCOUNT_ID                 = "592172380963"
    AWS_DEFAULT_REGION             = "us-east-2"
    CELERY_BROKER                  = "redis"
    CLICKHOUSE_DB                  = "kainam_dev"
    CLICKHOUSE_HOST                = "3.135.214.254"
    CLICKHOUSE_PASSWORD            = "Kainam2023"
    CLICKHOUSE_PORT                = "8123"
    CLICKHOUSE_USER                = "default"
    DATA_CATALOG                   = "813dcf27-3de3-4c07-bfb0-140977739ee8"
    DB_EXTERNAL_DATASET_COLLECTION = "externalDatasets"
    DB_EXTERNAL_METADATA_COLL      = "sys_metadata"
    DB_IAM                         = "813dcf27-3de3-4c07-bfb0-140977739ee8"
    DB_METADATA_COLLECTION         = "sys_metadata"
    DEBUG                          = "True"
    EVALUATE_MODELS_CELERY         = "True"
    FEATURE_XICORRS_CELERY         = "True"
    GCP_BUCKET_NAME                = "trained_ezml_models"
    GOOGLE_API_KEY                 = "AIzaSyA08PyKBemVEnh7t4qdnSG2XUJFWreLPZQ"
    IS_KIMBALL_ENABLED             = "False"
    KIMBALL_HOST                   = "http://localhost:8081"
    MODELS                         = "autoreg,sarimaX,autoregX"
    MONGO_HOST                     = "dev.kj6fy.mongodb.net"
    MONGO_PASSWORD                 = "pZJ0t5nQPwkOJ7BK"
    MONGO_USERNAME                 = "generic-user"
    OPENAI_API_KEY                 = var.openai_api_key
    REDIS_CLUSTER_ENABLED          = "False"
    REDIS_DB                       = "1"
    REDIS_DEFAULT_DB               = "0"
    REDIS_HOST                     = module.elasticache.primary_endpoint_address
    REDIS_PASSWORD                 = var.elasticache_auth_token
    REDIS_PORT                     = "6379"
    REDIS_SSL                      = "True"
    REDIS_USER                     = "senna-app-user-dev"
    REDIS_XICORRS_DB               = "1"
    REGRESSORS                     = "LinearRegression,LGBM,LGBMX"
    SECRET_KEY                     = "sqyFByB2L7kY0tWCK1N25lbWNEpKlFSs8ONlffpQ63SEn1FYpWFvlbW9KUN2TWisOJcYNtqppPgq"
    SESSION_PERMANENT              = "True"
    SESSION_TYPE                   = "redis"
    SESSION_USE_SIGNER             = "False"
    SQS_QUEUE_NAME                 = "senna-celery-tasks-uat"
    SQS_QUEUE_URL                  = "https://sqs.us-east-2.amazonaws.com/592172380963/senna-celery-tasks-uat"
    USE_STORED_FEATURES            = "False"
    XICORR_WORKERS                 = "12"
  }

  # IAM Configuration
  access_role_arn   = module.iam_roles.app_runner_access_role_arn
  instance_role_arn = module.iam_roles.app_runner_instance_role_arn

  # Network Configuration
  is_publicly_accessible = true
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnet_ids
  create_vpc_connector   = true

  # Health Check Configuration - Using App Runner defaults
  health_check_enabled             = true
  health_check_path                = "/"
  health_check_protocol            = "TCP"
  health_check_interval            = 10
  health_check_timeout             = 5
  health_check_healthy_threshold   = 1
  health_check_unhealthy_threshold = 5

  # Auto Deployment
  auto_deployments_enabled = true

  common_tags = local.common_tags
}

# ===================================
# SENNA Frontend App Runner Service
# ===================================

module "senna_frontend" {
  source = "../../modules/app-runner"

  # Basic Configuration
  project_name = local.project_name
  environment  = local.environment
  service_name = "senna-front" # Matches kainam-senna-front-dev

  # ECR Configuration
  ecr_repository_url = module.ecr.repository_urls.frontend
  image_tag          = "latest"

  # App Configuration
  port   = "3000" # Standard React/Next.js port
  cpu    = "1024" # 1 vCPU as specified
  memory = "2048" # 2 GB as specified

  # Environment Variables for Frontend - Match working UAT pattern
  environment_variables = {
    BASE_SECRET                  = var.senna_base_secret # UAT has this as env var, not secret
    NEXTAUTH_URL                 = "https://ceamr2gi9c.us-east-2.awsapprunner.com/api/auth"
    NEXT_PUBLIC_BASE_BACK_URL    = var.senna_api_base_url
    NEXT_PUBLIC_BASE_KIMBALL_URL = "http://0.0.0.0:8081"
    NEXT_PUBLIC_FAVICON_URL      = "/images/favicon.ico"
    NEXT_PUBLIC_IS_DUMMY         = "false"
    NEXT_PUBLIC_LOGO_URL         = "/images/SENNA-Logo.png"
    NEXT_PUBLIC_PREFIX_BACK_URL  = "/v1"
  }

  # Environment Secrets - Empty to match UAT pattern
  environment_secrets = {}

  # IAM Configuration
  access_role_arn   = module.iam_roles.app_runner_access_role_arn
  instance_role_arn = module.iam_roles.app_runner_instance_role_arn

  # Network Configuration
  is_publicly_accessible = true
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnet_ids
  create_vpc_connector   = false # Frontend doesn't need VPC access

  # Health Check Configuration - Standard for frontend
  health_check_enabled             = true
  health_check_path                = "/"
  health_check_protocol            = "HTTP"
  health_check_interval            = 10
  health_check_timeout             = 5
  health_check_healthy_threshold   = 1
  health_check_unhealthy_threshold = 5

  # Custom Domain Configuration - Now enabling for working service
  enable_custom_domain   = true
  custom_domain_name     = "senna-dev.kainam.app"
  domain_certificate_arn = data.aws_acm_certificate.wildcard_kainam_app.arn

  # Auto Deployment
  auto_deployments_enabled = true

  common_tags = local.common_tags
}

# ===================================
# Kainam Platform Frontend App Runner Service
# ===================================

module "kainam_platform_frontend" {
  source = "../../modules/app-runner"

  # Basic Configuration
  project_name = local.project_name
  environment  = local.environment
  service_name = "platform-front"

  # ECR Configuration
  ecr_repository_url = module.kainam_platform_ecr.repository_urls.frontend
  image_tag          = "latest"

  # App Configuration
  port   = "3000"
  cpu    = "1024" # 1 vCPU
  memory = "2048" # 2 GB

  # Environment Variables (inherited from CI/CD pipeline)
  environment_variables = {
    NODE_ENV = "production"
  }

  # IAM Configuration
  access_role_arn   = module.iam_roles.app_runner_access_role_arn
  instance_role_arn = module.iam_roles.app_runner_instance_role_arn

  # Network Configuration
  is_publicly_accessible = true
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnet_ids
  create_vpc_connector   = false # Frontend doesn't need VPC access

  # Health Check Configuration - DISABLED due to missing Dockerfile health check
  health_check_enabled             = false

  # Custom Domain Configuration
  enable_custom_domain   = true
  custom_domain_name     = "console-dev.kainam.app"
  domain_certificate_arn = data.aws_acm_certificate.wildcard_kainam_app.arn

  # Auto Deployment
  auto_deployments_enabled = true

  common_tags = local.common_tags
}

# =============================================================================
# EC2 SENNA Models (Celery Workers)
# =============================================================================

module "senna_ec2_models" {
  source = "../../modules/ec2-senna-models"

  # Project Configuration
  project_name = local.project_name
  environment  = local.environment

  # Instance Configuration
  instance_name = "senna-celery-models"
  instance_type = "c6i.xlarge"
  ami_id        = "ami-0cfde0ea8edd312d4" # Ubuntu AMI that supports 16GB volumes

  # Network Configuration
  vpc_id                      = module.vpc.vpc_id
  subnet_id                   = module.vpc.public_subnet_ids[0] # Use first public subnet
  associate_public_ip_address = true

  # Security Group Configuration
  create_security_group = true
  security_group_name   = "senna-net-sg-ec2"

  ingress_rules = [
    {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress_rules = [
    {
      description = "All outbound traffic"
      from_port   = -1
      to_port     = -1
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  # IAM Configuration
  create_iam_role = true
  iam_role_name   = "senna-ec2-worker-role"

  iam_managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]

  iam_custom_policies = [
    {
      name        = "senna-ec2-worker-sqs-policy"
      description = "Policy to allow EC2 workers to consume messages from SQS"
      policy_json = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "sqs:ListQueues",
              "sqs:CreateQueue",
              "sqs:TagQueue"
            ]
            Resource = "*"
          },
          {
            Effect = "Allow"
            Action = [
              "sqs:DeleteQueue",
              "sqs:SetQueueAttributes",
              "sqs:ReceiveMessage",
              "sqs:DeleteMessage",
              "sqs:GetQueueAttributes",
              "sqs:GetQueueUrl",
              "sqs:SendMessage",
              "sqs:SendMessageBatch",
              "sqs:DeleteMessageBatch",
              "sqs:ChangeMessageVisibility",
              "sqs:ChangeMessageVisibilityBatch"
            ]
            Resource = [
              "arn:aws:sqs:${local.aws_region}:${var.aws_account_id}:senna-celery-tasks-dev",
              "arn:aws:sqs:${local.aws_region}:${var.aws_account_id}:senna-celery-tasks-dlq-dev"
            ]
          }
        ]
      })
    }
  ]

  # Key Pair Configuration
  create_key_pair     = true
  key_pair_name       = "senna-celery-models-key"
  key_pair_public_key = var.senna_ec2_ssh_public_key

  # Storage Configuration - Single 16GB root volume
  root_volume_size      = 16 # Reduced size as requested
  root_volume_type      = "gp3"
  root_volume_encrypted = true

  # No additional volumes - using single root volume only
  additional_volumes = []

  # Monitoring
  enable_detailed_monitoring = true

  # Tags
  additional_tags = {
    Purpose     = "ML Models and Celery Workers"
    Application = "SENNA"
    Component   = "Celery Workers"
  }
}

# =============================================================================
# EC2 KEYCLOAK AUTHENTICATION SERVICE
# =============================================================================

module "keycloak_ec2" {
  source = "../../modules/ec2-keycloak"

  # Project Configuration
  project_name   = local.project_name
  environment    = local.environment
  aws_region     = local.aws_region
  aws_account_id = var.aws_account_id

  # Instance Configuration
  instance_type = "t3.medium"
  ami_id        = "ami-0ea3c35c5c3284d82" # Ubuntu 22.04 LTS

  # Network Configuration
  vpc_id                      = module.vpc.vpc_id
  subnet_id                   = module.vpc.private_subnet_ids[0] # Deploy in private subnet
  associate_public_ip_address = false                            # Private deployment

  # Security Configuration
  alb_security_group_id = module.security_groups.alb_security_group_id

  # Keycloak Configuration
  keycloak_hostname  = "${local.auth_subdomain}.${local.base_domain}" # auth-dev.kainam.app
  keycloak_http_port = 8080
  container_name     = "keycloak-auth-${local.environment}"

  # Database Configuration
  rds_endpoint  = module.rds.db_instance_endpoint
  database_name = module.rds.db_name
  database_port = module.rds.db_instance_port

  # ECR Configuration
  ecr_repository_url = module.ecr.repository_urls.keycloak
  image_tag          = "latest"

  # Secrets Manager Configuration
  database_secret_name = module.secrets_manager.database_secret_name
  keycloak_secret_name = module.secrets_manager.keycloak_admin_secret_name

  # IAM Configuration
  create_iam_role = true

  # Storage Configuration
  root_volume_size      = 20
  root_volume_type      = "gp3"
  root_volume_encrypted = true

  # Monitoring Configuration
  enable_detailed_monitoring = true

  # SSH Configuration
  enable_ssh_access     = true
  ssh_trusted_ip_ranges = local.keycloak_trusted_ip_ranges
  ssh_public_key        = var.keycloak_ssh_public_key

  # Tags
  additional_tags = merge(local.common_tags, {
    Purpose     = "Keycloak Authentication Service"
    Application = "Authentication"
    Component   = "Keycloak"
    Service     = "keycloak"
  })
}

# Target Group Attachment for Keycloak EC2 Instance
resource "aws_lb_target_group_attachment" "keycloak" {
  target_group_arn = module.target_groups.keycloak_target_group_arn
  target_id        = module.keycloak_ec2.instance_id
  port             = module.keycloak_ec2.keycloak_http_port
}

# ===================================
# VPC ENDPOINTS FOR SESSION MANAGER
# ===================================

# VPC Endpoint for SSM
resource "aws_vpc_endpoint" "ssm" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${local.aws_region}.ssm"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [module.vpc.private_subnet_ids[0]]
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name      = "${local.project_name}-ssm-endpoint-${local.environment}"
    Component = "vpc-endpoint"
    Purpose   = "Session Manager SSM endpoint"
  })
}

# VPC Endpoint for EC2 Messages
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${local.aws_region}.ec2messages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [module.vpc.private_subnet_ids[0]]
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name      = "${local.project_name}-ec2messages-endpoint-${local.environment}"
    Component = "vpc-endpoint"
    Purpose   = "Session Manager EC2 messages endpoint"
  })
}

# VPC Endpoint for SSM Messages
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${local.aws_region}.ssmmessages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [module.vpc.private_subnet_ids[0]]
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name      = "${local.project_name}-ssmmessages-endpoint-${local.environment}"
    Component = "vpc-endpoint"
    Purpose   = "Session Manager SSM messages endpoint"
  })
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${local.project_name}-vpc-endpoints-${local.environment}-"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  # Ingress rule: Allow HTTPS traffic from private subnets
  ingress {
    description = "HTTPS from private subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.private_subnet_cidrs[0], module.vpc.private_subnet_cidrs[1]]
  }

  # Egress rule: Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name      = "${local.project_name}-vpc-endpoints-sg-${local.environment}"
    Component = "security-group"
    Purpose   = "VPC endpoints network security"
  })
}

# =============================================================================
# ISSUE-012 FIX: ALB-to-Keycloak Security Group Rule
# =============================================================================
# This rule allows the ALB to communicate with the Keycloak EC2 instance
# for health checks and request routing. This addresses the security group
# mismatch that was causing health check timeouts.

resource "aws_vpc_security_group_egress_rule" "alb_to_keycloak" {
  security_group_id = module.security_groups.alb_security_group_id
  description       = "Allow HTTP traffic from ALB to Keycloak authentication service"

  referenced_security_group_id = module.keycloak_ec2.security_group_id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"

  tags = merge(local.common_tags, {
    Name      = "alb-to-keycloak-egress"
    Component = "security-rule"
    Purpose   = "ISSUE-012-fix"
  })
}