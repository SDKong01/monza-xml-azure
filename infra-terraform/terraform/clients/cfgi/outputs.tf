# =============================================================================
# CFGI CLIENT INFRASTRUCTURE OUTPUTS
# =============================================================================
# 
# Outputs provide visibility into deployed infrastructure and enable integration
# between services. These values are used for:
#   - Service-to-service communication
#   - Manual configuration steps
#   - Documentation and verification
#
# =============================================================================

# =============================================================================
# FOUNDATION INFRASTRUCTURE OUTPUTS (CFGI-002, CFGI-003, CFGI-004)
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Outputs (CFGI-002) - ACTIVE
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the CFGI VPC"
  value       = try(module.vpc.vpc_id, null)
}

output "vpc_cidr_block" {
  description = "CIDR block of the CFGI VPC"
  value       = try(module.vpc.vpc_cidr_block, null)
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = try(module.vpc.public_subnet_ids, [])
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = try(module.vpc.private_subnet_ids, [])
}

# -----------------------------------------------------------------------------
# Security Groups Outputs (CFGI-003) - Will be added after deployment
# -----------------------------------------------------------------------------

# output "alb_security_group_id" {
#   description = "ID of the ALB security group"
#   value       = try(module.security_groups.alb_security_group_id, null)
# }

# output "web_security_group_id" {
#   description = "ID of the web tier security group"
#   value       = try(module.security_groups.web_security_group_id, null)
# }

# -----------------------------------------------------------------------------
# IAM Roles Outputs (CFGI-004) - ACTIVE
# -----------------------------------------------------------------------------

output "app_runner_access_role_arn" {
  description = "ARN of the App Runner access role for ECR"
  value       = try(module.iam_roles.app_runner_access_role_arn, null)
}

output "app_runner_instance_role_arn" {
  description = "ARN of the App Runner instance role"
  value       = try(module.iam_roles.app_runner_instance_role_arn, null)
}

output "ec2_instance_role_arn" {
  description = "ARN of the EC2 instance role for Monza"
  value       = try(module.iam_roles.ec2_instance_role_arn, null)
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile for Monza"
  value       = try(module.iam_roles.ec2_instance_profile_arn, null)
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile for Monza"
  value       = try(module.iam_roles.ec2_instance_profile_name, null)
}

# =============================================================================
# KIMBALL PRODUCT OUTPUTS (CFGI-005) - ECR Repositories
# =============================================================================

output "kimball_api_ecr_url" {
  description = "URL of the Kimball API ECR repository"
  value       = try(module.ecr_kimball.api_repository_url, null)
}

output "kimball_api_ecr_arn" {
  description = "ARN of the Kimball API ECR repository"
  value       = try(module.ecr_kimball.api_repository_arn, null)
}

output "kimball_frontend_ecr_url" {
  description = "URL of the Kimball frontend ECR repository"
  value       = try(module.ecr_kimball.frontend_repository_url, null)
}

output "kimball_frontend_ecr_arn" {
  description = "ARN of the Kimball frontend ECR repository"
  value       = try(module.ecr_kimball.frontend_repository_arn, null)
}

output "ecr_registry_id" {
  description = "ECR registry ID for CFGI account"
  value       = try(module.ecr_kimball.api_registry_id, null)
}

# output "kimball_frontend_service_url" {
#   description = "URL of the Kimball frontend App Runner service"
#   value       = try(module.kimball_frontend.service_url, null)
# }

# output "kimball_backend_service_url" {
#   description = "URL of the Kimball backend App Runner service"
#   value       = try(module.kimball_backend.service_url, null)
# }

# output "kimball_frontend_custom_domain" {
#   description = "Custom domain for Kimball frontend"
#   value       = try(module.kimball_frontend.custom_domain_name, "kimball-cfgi.kainam.app")
# }

# output "kimball_frontend_dns_target" {
#   description = "DNS target for Kimball frontend custom domain (for Route 53 configuration)"
#   value       = try(module.kimball_frontend.dns_target, null)
# }

# =============================================================================
# CI/CD PIPELINE OUTPUTS (Disabled - Manual Docker image pushes)
# =============================================================================

# output "kimball_frontend_pipeline_name" {
#   description = "Name of the Kimball frontend CodePipeline"
#   value       = try(module.codepipeline_kimball.frontend_pipeline_name, null)
# }
# 
# output "kimball_frontend_pipeline_arn" {
#   description = "ARN of the Kimball frontend CodePipeline"
#   value       = try(module.codepipeline_kimball.frontend_pipeline_arn, null)
# }
# 
# output "kimball_api_pipeline_name" {
#   description = "Name of the Kimball API CodePipeline"
#   value       = try(module.codepipeline_kimball.api_pipeline_name, null)
# }
# 
# output "kimball_api_pipeline_arn" {
#   description = "ARN of the Kimball API CodePipeline"
#   value       = try(module.codepipeline_kimball.api_pipeline_arn, null)
# }
# 
# output "kimball_frontend_codebuild_project" {
#   description = "Name of the Kimball frontend CodeBuild project"
#   value       = try(module.codepipeline_kimball.frontend_codebuild_project, null)
# }
# 
# output "kimball_api_codebuild_project" {
#   description = "Name of the Kimball API CodeBuild project"
#   value       = try(module.codepipeline_kimball.api_codebuild_project, null)
# }

# =============================================================================
# MONZA PRODUCT OUTPUTS (PLACEHOLDER)
# =============================================================================
# These outputs will be uncommented when Monza infrastructure is deployed

# output "monza_instance_id" {
#   description = "ID of the Monza EC2 instance"
#   value       = try(module.monza.instance_id, null)
# }

# output "monza_private_ip" {
#   description = "Private IP address of Monza EC2 instance"
#   value       = try(module.monza.private_ip, null)
# }

# output "monza_public_ip" {
#   description = "Public IP address of Monza EC2 instance (if applicable)"
#   value       = try(module.monza.public_ip, null)
# }

# =============================================================================
# DEPLOYMENT INFORMATION
# =============================================================================

output "deployment_region" {
  description = "AWS region where infrastructure is deployed"
  value       = "us-east-2"
}

output "project_name" {
  description = "Project name for resource identification"
  value       = "cfgi"
}

output "environment" {
  description = "Environment name"
  value       = "prod"
}
