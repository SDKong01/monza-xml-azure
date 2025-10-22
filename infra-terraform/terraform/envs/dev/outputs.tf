# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = module.vpc.vpc_arn
}

# Public Subnet Outputs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = module.vpc.public_subnet_cidrs
}

# Private Subnet Outputs
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = module.vpc.private_subnet_cidrs
}

# Availability Zone Outputs
output "availability_zones" {
  description = "List of availability zones used"
  value       = module.vpc.availability_zones
}

# Internet Gateway Outputs
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

# NAT Gateway Outputs
output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = module.vpc.nat_gateway_id
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT Gateway"
  value       = module.vpc.nat_gateway_public_ip
}

# Route Table Outputs
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = module.vpc.public_route_table_id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = module.vpc.private_route_table_id
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.security_groups.alb_security_group_id
}

output "web_security_group_id" {
  description = "ID of the web tier security group"
  value       = module.security_groups.web_security_group_id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = module.security_groups.db_security_group_id
}

output "security_group_ids" {
  description = "Map of all security group IDs"
  value       = module.security_groups.security_group_ids
}

# Convenience Outputs
output "public_subnet_by_az" {
  description = "Map of availability zone to public subnet ID"
  value       = module.vpc.public_subnet_by_az
}

output "private_subnet_by_az" {
  description = "Map of availability zone to private subnet ID"
  value       = module.vpc.private_subnet_by_az
}

# ETL Network Outputs
output "etl_public_subnet_id" {
  description = "ID of the ETL public subnet"
  value       = module.kimball_etl_networking.etl_public_subnet_id
}

output "etl_private_subnet_id" {
  description = "ID of the ETL private subnet"
  value       = module.kimball_etl_networking.etl_private_subnet_id
}

output "etl_subnet_ids" {
  description = "Map of ETL subnet IDs"
  value       = module.kimball_etl_networking.etl_subnet_ids
}

output "etl_external_security_group_id" {
  description = "ID of the ETL external services security group"
  value       = module.kimball_etl_networking.etl_external_security_group_id
}

output "etl_internal_security_group_id" {
  description = "ID of the ETL internal services security group"
  value       = module.kimball_etl_networking.etl_internal_security_group_id
}

output "etl_database_security_group_id" {
  description = "ID of the ETL database services security group"
  value       = module.kimball_etl_networking.etl_database_security_group_id
}

output "etl_security_group_ids" {
  description = "Map of ETL security group IDs"
  value       = module.kimball_etl_networking.etl_security_group_ids
}

output "etl_network_summary" {
  description = "Summary of Kimball ETL networking resources"
  value       = module.kimball_etl_networking.etl_network_summary
}

# Secrets Manager Outputs
output "database_secret_arn" {
  description = "ARN of the database secret"
  value       = module.secrets_manager.database_secret_arn
  sensitive   = true
}

output "database_secret_name" {
  description = "Name of the database secret"
  value       = module.secrets_manager.database_secret_name
}

output "keycloak_admin_secret_arn" {
  description = "ARN of the Keycloak admin secret"
  value       = module.secrets_manager.keycloak_admin_secret_arn
  sensitive   = true
}

output "keycloak_admin_secret_name" {
  description = "Name of the Keycloak admin secret"
  value       = module.secrets_manager.keycloak_admin_secret_name
}

output "backend_client_secret_arn" {
  description = "ARN of the SENNA backend client secret"
  value       = module.secrets_manager.backend_client_secret_arn
  sensitive   = true
}

output "backend_client_secret_name" {
  description = "Name of the SENNA backend client secret"
  value       = module.secrets_manager.backend_client_secret_name
}

output "secret_arns" {
  description = "Map of all secret ARNs for IAM policy creation"
  value       = module.secrets_manager.secret_arns
  sensitive   = true
}

output "secret_names" {
  description = "Map of all secret names"
  value       = module.secrets_manager.secret_names
}

output "secrets_summary" {
  description = "Summary of all created secrets"
  value       = module.secrets_manager.secrets_summary
}

# IAM Outputs
output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role for secrets access"
  value       = module.secrets_manager.ec2_role_arn
}

output "ec2_role_name" {
  description = "Name of the EC2 IAM role for secrets access"
  value       = module.secrets_manager.ec2_role_name
}

output "secrets_policy_arn" {
  description = "ARN of the secrets manager read policy"
  value       = module.secrets_manager.secrets_policy_arn
}

output "instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = module.secrets_manager.instance_profile_arn
}

output "instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = module.secrets_manager.instance_profile_name
}

output "iam_summary" {
  description = "Summary of all created IAM resources"
  value       = module.secrets_manager.iam_summary
}

# ===================================
# RDS PostgreSQL Outputs
# ===================================

output "rds_instance_id" {
  description = "The RDS instance ID"
  value       = module.rds.db_instance_id
}

output "rds_instance_identifier" {
  description = "The RDS instance identifier"
  value       = module.rds.db_instance_identifier
}

output "rds_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.rds.db_instance_arn
}

output "rds_instance_endpoint" {
  description = "The RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "rds_instance_port" {
  description = "The database port"
  value       = module.rds.db_instance_port
}

output "rds_database_name" {
  description = "The database name"
  value       = module.rds.db_name
}

output "rds_jdbc_url" {
  description = "JDBC URL for PostgreSQL connection (for Keycloak)"
  value       = module.rds.db_jdbc_url
  sensitive   = true
}

output "rds_security_group_id" {
  description = "The ID of the RDS security group"
  value       = module.rds.db_security_group_id
}

output "rds_subnet_group_id" {
  description = "The db subnet group name"
  value       = module.rds.db_subnet_group_id
}

output "rds_summary" {
  description = "Summary of RDS instance configuration"
  value       = module.rds.rds_summary
}

# Authentication ALB Outputs
output "auth_alb_arn" {
  description = "ARN of the authentication ALB"
  value       = module.auth_alb.alb_arn
}

output "auth_alb_dns_name" {
  description = "DNS name of the authentication ALB"
  value       = module.auth_alb.alb_dns_name
}

output "auth_alb_zone_id" {
  description = "Hosted zone ID of the authentication ALB"
  value       = module.auth_alb.alb_zone_id
}

# Target Group Outputs
output "keycloak_target_group_arn" {
  description = "ARN of the Keycloak target group"
  value       = module.target_groups.keycloak_target_group_arn
}

output "keycloak_target_group_name" {
  description = "Name of the Keycloak target group"
  value       = module.target_groups.keycloak_target_group_name
}

# ALB Listener Outputs
output "http_listener_arn" {
  description = "ARN of the HTTP redirect listener"
  value       = module.alb_listeners.http_listener_arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS forward listener"
  value       = module.alb_listeners.https_listener_arn
}

output "redirect_configuration" {
  description = "HTTP to HTTPS redirect configuration"
  value       = module.alb_listeners.redirect_configuration
}

# DNS Outputs
output "auth_service_url" {
  description = "Full HTTPS URL for the authentication service"
  value       = module.route53_records.auth_service_url
}

output "auth_dns_record_fqdn" {
  description = "Fully qualified domain name of the authentication record"
  value       = module.route53_records.auth_dns_record_fqdn
}

output "dns_configuration_summary" {
  description = "Summary of the DNS configuration"
  value       = module.route53_records.dns_configuration_summary
}

# Authentication Infrastructure Summary
output "authentication_infrastructure_summary" {
  description = "Complete summary of authentication infrastructure"
  value = {
    alb_dns_name      = module.auth_alb.alb_dns_name
    service_url       = module.route53_records.auth_service_url
    target_group      = module.target_groups.keycloak_target_group_name
    ssl_policy        = module.alb_listeners.https_ssl_policy
    certificate_arn   = data.aws_acm_certificate.wildcard_kainam_app.arn
    hosted_zone_id    = data.aws_route53_zone.kainam_app.zone_id
    health_check_path = module.target_groups.keycloak_health_check_path
  }
}

# ===================================
# SENNA ECR Module Outputs
# ===================================

output "ecr_repository_urls" {
  description = "URLs of all SENNA ECR repositories"
  value       = module.ecr.repository_urls
}

output "ecr_repository_names" {
  description = "Names of all SENNA ECR repositories"
  value       = module.ecr.repository_names
}

output "ecr_api_repository_url" {
  description = "URL of the SENNA API ECR repository"
  value       = module.ecr.api_repository_url
}

output "ecr_frontend_repository_url" {
  description = "URL of the SENNA Frontend ECR repository"
  value       = module.ecr.frontend_repository_url
}

output "ecr_models_repository_url" {
  description = "URL of the SENNA Models ECR repository"
  value       = module.ecr.models_repository_url
}

output "ecr_keycloak_repository_url" {
  description = "URL of the Keycloak ECR repository"
  value       = module.ecr.keycloak_repository_url
}

output "ecr_registry_id" {
  description = "ECR registry ID"
  value       = module.ecr.ecr_registry_id
}

# ===================================
# Kainam Platform ECR Module Outputs
# ===================================

output "kainam_platform_ecr_repository_urls" {
  description = "URLs of all Kainam Platform ECR repositories"
  value       = module.kainam_platform_ecr.repository_urls
}

output "kainam_platform_ecr_repository_names" {
  description = "Names of all Kainam Platform ECR repositories"
  value       = module.kainam_platform_ecr.repository_names
}

output "kainam_platform_api_repository_url" {
  description = "URL of the Kainam Platform API ECR repository"
  value       = module.kainam_platform_ecr.api_repository_url
}

output "kainam_platform_frontend_repository_url" {
  description = "URL of the Kainam Platform Frontend ECR repository"
  value       = module.kainam_platform_ecr.frontend_repository_url
}

output "kainam_platform_ecr_registry_id" {
  description = "ECR registry ID for Kainam Platform repositories"
  value       = module.kainam_platform_ecr.ecr_registry_id
}

output "kainam_platform_repository_arns" {
  description = "ARNs of all Kainam Platform ECR repositories"
  value       = module.kainam_platform_ecr.repository_arns
}

# ===================================
# Combined ECR Summary
# ===================================

output "all_ecr_repositories_summary" {
  description = "Summary of all ECR repositories (SENNA + Kainam Platform)"
  value = {
    senna_repositories = {
      api      = module.ecr.api_repository_url
      frontend = module.ecr.frontend_repository_url
      models   = module.ecr.models_repository_url
      keycloak = module.ecr.keycloak_repository_url
    }
    kainam_platform_repositories = {
      api      = module.kainam_platform_ecr.api_repository_url
      frontend = module.kainam_platform_ecr.frontend_repository_url
    }
    registry_id        = module.ecr.ecr_registry_id
    total_repositories = 6
  }
}

# ===================================
# ElastiCache Module Outputs
# ===================================

output "elasticache_cluster_id" {
  description = "ID of the ElastiCache cluster"
  value       = module.elasticache.cluster_id
}

output "elasticache_cluster_arn" {
  description = "ARN of the ElastiCache cluster"
  value       = module.elasticache.cluster_arn
}

output "elasticache_primary_endpoint_address" {
  description = "Primary endpoint address for connecting to the cache"
  value       = module.elasticache.primary_endpoint_address
}

output "elasticache_port" {
  description = "Port number of the cache endpoint"
  value       = module.elasticache.port
}

output "elasticache_engine" {
  description = "Cache engine"
  value       = module.elasticache.engine
}

output "elasticache_engine_version" {
  description = "Cache engine version"
  value       = module.elasticache.engine_version
}

output "elasticache_security_group_id" {
  description = "ID of the security group created for the cache cluster"
  value       = module.elasticache.security_group_id
}

output "elasticache_subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = module.elasticache.subnet_group_name
}

output "elasticache_parameter_group_id" {
  description = "ID of the ElastiCache parameter group"
  value       = module.elasticache.parameter_group_id
}

output "elasticache_connection_info" {
  description = "Connection information for the ElastiCache cluster"
  value       = module.elasticache.connection_info
}

output "elasticache_summary" {
  description = "Summary of ElastiCache cluster configuration"
  value       = module.elasticache.elasticache_summary
}

# ===================================
# IAM Roles Outputs
# ===================================

output "iam_github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = module.iam_roles.github_oidc_provider_arn
}

output "iam_github_actions_role_arn" {
  description = "ARN of the GitHub Actions ECR push role"
  value       = module.iam_roles.github_actions_role_arn
}

output "iam_app_runner_access_role_arn" {
  description = "ARN of the App Runner access role"
  value       = module.iam_roles.app_runner_access_role_arn
}

output "iam_app_runner_instance_role_arn" {
  description = "ARN of the App Runner instance role"
  value       = module.iam_roles.app_runner_instance_role_arn
}

output "iam_ec2_instance_role_arn" {
  description = "ARN of the EC2 instance role"
  value       = module.iam_roles.ec2_instance_role_arn
}

output "iam_ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = module.iam_roles.ec2_instance_profile_arn
}

output "iam_ec2_worker_role_arn" {
  description = "ARN of the EC2 worker role"
  value       = module.iam_roles.ec2_worker_role_arn
}

output "iam_ec2_worker_instance_profile_arn" {
  description = "ARN of the EC2 worker instance profile"
  value       = module.iam_roles.ec2_worker_instance_profile_arn
}

output "iam_roles_summary" {
  description = "Summary of all created IAM roles"
  value       = module.iam_roles.iam_roles_summary
}

output "iam_github_actions_usage_instructions" {
  description = "Instructions for using the GitHub Actions role in workflows"
  value       = module.iam_roles.github_actions_usage_instructions
}

# ===================================
# CodePipeline Outputs
# ===================================

output "codepipeline_frontend_pipeline_arn" {
  description = "ARN of the frontend CodePipeline"
  value       = module.codepipeline.frontend_pipeline_arn
}

output "codepipeline_frontend_pipeline_name" {
  description = "Name of the frontend CodePipeline"
  value       = module.codepipeline.frontend_pipeline_name
}

output "codepipeline_api_pipeline_arn" {
  description = "ARN of the API CodePipeline"
  value       = module.codepipeline.api_pipeline_arn
}

output "codepipeline_api_pipeline_name" {
  description = "Name of the API CodePipeline"
  value       = module.codepipeline.api_pipeline_name
}

output "codepipeline_models_pipeline_arn" {
  description = "ARN of the models CodePipeline"
  value       = module.codepipeline.models_pipeline_arn
}

output "codepipeline_models_pipeline_name" {
  description = "Name of the models CodePipeline"
  value       = module.codepipeline.models_pipeline_name
}

output "codepipeline_summary" {
  description = "Summary of all CodePipeline resources"
  value       = module.codepipeline.codepipeline_summary
}

# ===================================
# Kainam Platform CodePipeline Outputs
# ===================================

output "codepipeline_kainam_platform_api_pipeline_arn" {
  description = "ARN of the Kainam Platform API CodePipeline"
  value       = module.codepipeline.kainam_platform_api_pipeline_arn
}

output "codepipeline_kainam_platform_api_pipeline_name" {
  description = "Name of the Kainam Platform API CodePipeline"
  value       = module.codepipeline.kainam_platform_api_pipeline_name
}

output "codepipeline_kainam_platform_frontend_pipeline_arn" {
  description = "ARN of the Kainam Platform frontend CodePipeline"
  value       = module.codepipeline.kainam_platform_frontend_pipeline_arn
}

output "codepipeline_kainam_platform_frontend_pipeline_name" {
  description = "Name of the Kainam Platform frontend CodePipeline"
  value       = module.codepipeline.kainam_platform_frontend_pipeline_name
}

# ===================================
# SENNA Infrastructure Summary
# ===================================

output "senna_infrastructure_summary" {
  description = "Complete summary of SENNA infrastructure"
  value = {
    ecr_repositories = module.ecr.repository_urls
    registry_id      = module.ecr.ecr_registry_id
    redis_endpoint   = module.elasticache.primary_endpoint_address
    redis_port       = module.elasticache.port
    iam_roles        = module.iam_roles.iam_roles_summary
    app_runner       = module.senna_api.app_runner_summary
    ec2_models       = module.senna_ec2_models.instance_summary
  }
}

# ===================================
# SENNA API App Runner Outputs
# ===================================

output "senna_api_service_arn" {
  description = "ARN of the SENNA API App Runner service"
  value       = module.senna_api.service_arn
}

output "senna_api_service_url" {
  description = "Public URL of the SENNA API App Runner service"
  value       = module.senna_api.service_url
}

output "senna_api_service_name" {
  description = "Name of the SENNA API App Runner service"
  value       = module.senna_api.service_name
}

output "senna_api_status" {
  description = "Status of the SENNA API App Runner service"
  value       = module.senna_api.status
}

output "senna_api_vpc_connector_arn" {
  description = "ARN of the SENNA API VPC connector"
  value       = module.senna_api.vpc_connector_arn
}

output "senna_api_security_group_id" {
  description = "ID of the SENNA API security group"
  value       = module.senna_api.security_group_id
}

output "senna_api_connection_info" {
  description = "Connection information for the SENNA API service"
  value       = module.senna_api.connection_info
}

# =============================================================================
# EC2 SENNA Models Outputs
# =============================================================================

output "senna_ec2_instance_id" {
  description = "ID of the SENNA EC2 models instance"
  value       = module.senna_ec2_models.instance_id
}

output "senna_ec2_instance_name" {
  description = "Name of the SENNA EC2 models instance"
  value       = module.senna_ec2_models.instance_name
}

output "senna_ec2_public_ip" {
  description = "Public IP address of the SENNA EC2 models instance"
  value       = module.senna_ec2_models.public_ip
}

output "senna_ec2_private_ip" {
  description = "Private IP address of the SENNA EC2 models instance"
  value       = module.senna_ec2_models.private_ip
}

output "senna_ec2_public_dns" {
  description = "Public DNS name of the SENNA EC2 models instance"
  value       = module.senna_ec2_models.public_dns
}

output "senna_ec2_key_pair_name" {
  description = "Name of the SSH key pair for the SENNA EC2 models instance"
  value       = module.senna_ec2_models.key_pair_name
}

output "senna_ec2_security_group_id" {
  description = "ID of the SENNA EC2 models security group"
  value       = module.senna_ec2_models.security_group_id
}

output "senna_ec2_iam_role_name" {
  description = "Name of the SENNA EC2 models IAM role"
  value       = module.senna_ec2_models.iam_role_name
}

output "senna_ec2_iam_instance_profile_name" {
  description = "Name of the SENNA EC2 models IAM instance profile"
  value       = module.senna_ec2_models.iam_instance_profile_name
}

output "senna_ec2_connection_info" {
  description = "Connection information for the SENNA EC2 models instance"
  value       = module.senna_ec2_models.connection_info
}

output "senna_ec2_instance_summary" {
  description = "Summary of the SENNA EC2 models instance configuration"
  value       = module.senna_ec2_models.instance_summary
}

# ===================================
# SENNA Frontend App Runner Outputs
# ===================================

output "senna_frontend_service_arn" {
  description = "ARN of the SENNA frontend App Runner service"
  value       = module.senna_frontend.service_arn
}

output "senna_frontend_service_name" {
  description = "Name of the SENNA frontend App Runner service"
  value       = module.senna_frontend.service_name
}

output "senna_frontend_service_url" {
  description = "Default App Runner URL for the SENNA frontend service"
  value       = module.senna_frontend.service_url
}

output "senna_frontend_status" {
  description = "Status of the SENNA frontend App Runner service"
  value       = module.senna_frontend.status
}

output "senna_frontend_connection_info" {
  description = "Connection information for the SENNA frontend service"
  value       = module.senna_frontend.connection_info
}

output "senna_frontend_certificate_validation_records" {
  description = "Certificate validation records for SENNA frontend custom domain"
  value       = module.senna_frontend.certificate_validation_records
}

output "senna_frontend_dns_target" {
  description = "DNS target for SENNA frontend custom domain (CNAME record value)"
  value       = module.senna_frontend.dns_target
}

# ===================================
# SENNA Route 53 DNS Outputs
# ===================================

output "senna_dns_record_fqdn" {
  description = "Fully qualified domain name for SENNA service"
  value       = module.route53_records.senna_dns_record_fqdn
}

output "senna_service_url" {
  description = "Full HTTPS URL for the SENNA frontend service"
  value       = module.route53_records.senna_service_url
}

output "senna_dns_configuration_summary" {
  description = "SENNA DNS configuration summary"
  value       = module.route53_records.senna_dns_configuration_summary
}

output "senna_certificate_validation_records_created" {
  description = "Certificate validation records created in Route 53"
  value       = module.route53_records.senna_certificate_validation_records_created
}

output "senna_certificate_validation_summary" {
  description = "Summary of certificate validation DNS records"
  value       = module.route53_records.senna_certificate_validation_summary
}

# ===================================
# Kainam Platform Frontend App Runner Outputs
# ===================================

output "kainam_platform_frontend_service_arn" {
  description = "ARN of the Kainam Platform frontend App Runner service"
  value       = module.kainam_platform_frontend.service_arn
}

output "kainam_platform_frontend_service_id" {
  description = "Service ID of the Kainam Platform frontend App Runner service"
  value       = module.kainam_platform_frontend.service_id
}

output "kainam_platform_frontend_service_url" {
  description = "Service URL of the Kainam Platform frontend App Runner service"
  value       = module.kainam_platform_frontend.service_url
}

output "kainam_platform_frontend_status" {
  description = "Status of the Kainam Platform frontend App Runner service"
  value       = module.kainam_platform_frontend.status
}

output "kainam_platform_frontend_dns_target" {
  description = "DNS target for the Kainam Platform frontend App Runner service"
  value       = module.kainam_platform_frontend.dns_target
}

output "kainam_platform_service_url" {
  description = "Full HTTPS URL for the Kainam Platform frontend service"
  value       = module.route53_records.kainam_platform_service_url
}

output "kainam_platform_dns_configuration_summary" {
  description = "Kainam Platform DNS configuration summary"
  value       = module.route53_records.kainam_platform_dns_configuration_summary
}