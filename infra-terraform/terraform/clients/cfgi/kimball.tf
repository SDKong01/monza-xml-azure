# =============================================================================
# CFGI CLIENT - KIMBALL PRODUCT INFRASTRUCTURE
# =============================================================================
#
# Kimball Product Stack:
#   - ECR repositories (frontend and API)
#   - App Runner services (frontend and backend)
#   - CI/CD pipelines (CodePipeline + CodeBuild)
#   - Route 53 DNS records
#
# Deployment Order:
#   1. ECR repositories
#   2. App Runner frontend service
#   3. App Runner backend service  
#   4. CI/CD pipelines
#   5. Route 53 DNS records
#
# =============================================================================

# =============================================================================
# DATA SOURCES
# =============================================================================
# 
# These data sources fetch existing resources needed for Kimball deployment:
#   - ACM certificate (manually created in CFGI account)
#   - Route 53 hosted zone (in Kainam account)
#
# =============================================================================

# ACM Certificate for *.kainam.app (manually created in CFGI account)
# data "aws_acm_certificate" "wildcard_kainam_app" {
#   domain      = "*.kainam.app"
#   statuses    = ["ISSUED"]
#   most_recent = true
# }

# Route 53 Hosted Zone for kainam.app (in Kainam account)
# Note: DNS records will be managed via Terraform but require cross-account access
# data "aws_route53_zone" "kainam_app" {
#   name         = "kainam.app"
#   private_zone = false
# }

# =============================================================================
# ECR REPOSITORIES
# =============================================================================
# 
# Container registries for Kimball frontend and backend Docker images
#
module "ecr_kimball" {
  source = "../../modules/ecr"

  environment                = local.environment
  project_name               = local.project_name
  service_name               = "kimball"
  create_api_repository      = true # kimball-api-ecr-prod
  create_frontend_repository = true # kimball-front-ecr-prod
  create_models_repository   = false
  create_keycloak_repository = false
  image_retention_count      = var.ecr_image_retention_count
  enable_image_scan_on_push  = var.ecr_enable_image_scanning
  repository_encryption_type = var.ecr_repository_encryption_type
  github_actions_principals  = [] # Not using GitHub Actions for CFGI
  common_tags                = local.common_tags
}

# =============================================================================
# APP RUNNER - FRONTEND SERVICE
# =============================================================================
# 
# Kimball frontend (React/Next.js) deployed as managed container service
# with custom domain kimball-cfgi.kainam.app
#
# module "kimball_frontend" {
#   source = "../../modules/app-runner"
#   
#   # Basic Configuration
#   project_name = local.project_name
#   environment  = local.environment
#   service_name = "kimball-frontend"
#   
#   # ECR Configuration
#   ecr_repository_url = module.ecr_kimball.repository_urls["frontend"]
#   image_tag          = "latest"
#   
#   # App Configuration
#   port   = "3000"
#   cpu    = tostring(var.kimball_frontend_cpu)
#   memory = tostring(var.kimball_frontend_memory)
#   
#   # Environment Variables (customize per client requirements)
#   environment_variables = {
#     NODE_ENV                = "production"
#     NEXT_PUBLIC_API_URL     = module.kimball_backend.service_url
#     NEXT_PUBLIC_ENVIRONMENT = "production"
#   }
#   
#   # IAM Configuration
#   access_role_arn   = module.iam_roles.app_runner_access_role_arn
#   instance_role_arn = module.iam_roles.app_runner_instance_role_arn
#   
#   # Network Configuration
#   is_publicly_accessible = true
#   create_vpc_connector   = false  # Frontend doesn't need VPC access
#   
#   # Health Check Configuration
#   health_check_enabled             = true
#   health_check_path                = "/"
#   health_check_protocol            = "HTTP"
#   health_check_interval            = 10
#   health_check_timeout             = 5
#   health_check_healthy_threshold   = 1
#   health_check_unhealthy_threshold = 5
#   
#   # Custom Domain Configuration
#   enable_custom_domain   = true
#   custom_domain_name     = local.kimball_domain
#   domain_certificate_arn = data.aws_acm_certificate.wildcard_kainam_app.arn
#   
#   # Auto Deployment
#   auto_deployments_enabled = true
#   
#   common_tags = local.common_tags
# }

# =============================================================================
# APP RUNNER - BACKEND SERVICE
# =============================================================================
# 
# Kimball backend (FastAPI) with VPC connector for Monza communication
#
# module "kimball_backend" {
#   source = "../../modules/app-runner"
#   
#   # Basic Configuration
#   project_name = local.project_name
#   environment  = local.environment
#   service_name = "kimball-api"
#   
#   # ECR Configuration
#   ecr_repository_url = module.ecr_kimball.repository_urls["api"]
#   image_tag          = "latest"
#   
#   # App Configuration
#   port   = "8000"
#   cpu    = tostring(var.kimball_backend_cpu)
#   memory = tostring(var.kimball_backend_memory)
#   
#   # Environment Variables (customize per client requirements)
#   environment_variables = {
#     ENVIRONMENT     = "production"
#     # CLICKHOUSE_HOST = module.monza.private_ip  # Uncomment after Monza deployment
#     # CLICKHOUSE_PORT = "8123"
#   }
#   
#   # IAM Configuration
#   access_role_arn   = module.iam_roles.app_runner_access_role_arn
#   instance_role_arn = module.iam_roles.app_runner_instance_role_arn
#   
#   # Network Configuration
#   is_publicly_accessible = true
#   vpc_id                 = module.vpc.vpc_id
#   subnet_ids             = module.vpc.private_subnet_ids
#   create_vpc_connector   = true  # Backend needs VPC access for Monza
#   
#   # Health Check Configuration
#   health_check_enabled             = true
#   health_check_path                = "/health"
#   health_check_protocol            = "HTTP"
#   health_check_interval            = 10
#   health_check_timeout             = 5
#   health_check_healthy_threshold   = 1
#   health_check_unhealthy_threshold = 5
#   
#   # Auto Deployment
#   auto_deployments_enabled = true
#   
#   common_tags = local.common_tags
# }

# =============================================================================
# CI/CD PIPELINES
# =============================================================================
# 
# CodePipeline + CodeBuild for automated Docker builds and ECR deployments
# NOTE: Disabled - Docker images will be pushed manually to ECR
#
# # Local variable for ECR repository URLs (module expects object with frontend, api, models keys)
# locals {
#   kimball_ecr_repository_urls = {
#     frontend = module.ecr_kimball.frontend_repository_url
#     api      = module.ecr_kimball.api_repository_url
#     models   = "" # Not used for Kimball
#   }
# }
# 
# module "codepipeline_kimball" {
#   source = "../../modules/codepipeline"
# 
#   environment  = local.environment
#   project_name = local.project_name
#   service_name = "kimball"
# 
#   # Pipeline Configuration
#   create_frontend_pipeline = true
#   create_api_pipeline      = true
#   create_models_pipeline   = false
#   create_keycloak_pipeline = false
#   source_branch            = var.kimball_github_branch
#   build_timeout            = var.codepipeline_build_timeout
# 
#   # GitHub Configuration
#   github_connection_arn = var.github_connection_arn
#   frontend_repository   = "${var.github_org}/${var.kimball_frontend_repo}"
#   api_repository        = "${var.github_org}/${var.kimball_api_repo}"
#   models_repository     = ""
# 
#   # ECR Configuration
#   ecr_repository_urls = local.kimball_ecr_repository_urls
#   ecr_registry_id     = module.ecr_kimball.api_registry_id
# 
#   # Frontend Build Environment Variables
#   # Note: NEXT_PUBLIC_HOST uses placeholder - update after App Runner backend deployment
#   frontend_environment_variables = [
#     {
#       name  = "NEXT_PUBLIC_HOST"
#       value = "placeholder_value"
#       type  = "PLAINTEXT"
#     },
#     {
#       name  = "NEXT_PUBLIC_DEV_PASSWORD"
#       value = "26ibQMsuNAQ25aJl"
#       type  = "PLAINTEXT"
#     }
#   ]
# 
#   common_tags = local.common_tags
# }

# =============================================================================
# ROUTE 53 DNS RECORDS
# =============================================================================
# 
# DNS records for kimball-cfgi.kainam.app custom domain
#
# module "route53_records_kimball" {
#   source = "../../modules/route53-records"
#   
#   environment  = local.environment
#   project_name = local.project_name
#   
#   # Kimball Frontend DNS Record
#   create_senna_dns_record = true  # Reusing variable name from existing module
#   senna_subdomain         = "kimball-cfgi"
#   senna_app_runner_url    = module.kimball_frontend.dns_target
#   
#   hosted_zone_id         = data.aws_route53_zone.kainam_app.zone_id
#   evaluate_target_health = true
#   common_tags            = local.common_tags
# }
