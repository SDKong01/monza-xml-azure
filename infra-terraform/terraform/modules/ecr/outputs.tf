# ECR Module Outputs
# Terraform module for managing AWS Elastic Container Registry (ECR) repositories

# API Repository Outputs
output "api_repository_arn" {
  description = "ARN of the API ECR repository"
  value       = var.create_api_repository ? aws_ecr_repository.api[0].arn : null
}

output "api_repository_name" {
  description = "Name of the API ECR repository"
  value       = var.create_api_repository ? aws_ecr_repository.api[0].name : null
}

output "api_repository_url" {
  description = "URL of the API ECR repository"
  value       = var.create_api_repository ? aws_ecr_repository.api[0].repository_url : null
}

output "api_registry_id" {
  description = "Registry ID where the API repository was created"
  value       = var.create_api_repository ? aws_ecr_repository.api[0].registry_id : null
}

# Frontend Repository Outputs
output "frontend_repository_arn" {
  description = "ARN of the Frontend ECR repository"
  value       = var.create_frontend_repository ? aws_ecr_repository.frontend[0].arn : null
}

output "frontend_repository_name" {
  description = "Name of the Frontend ECR repository"
  value       = var.create_frontend_repository ? aws_ecr_repository.frontend[0].name : null
}

output "frontend_repository_url" {
  description = "URL of the Frontend ECR repository"
  value       = var.create_frontend_repository ? aws_ecr_repository.frontend[0].repository_url : null
}

output "frontend_registry_id" {
  description = "Registry ID where the Frontend repository was created"
  value       = var.create_frontend_repository ? aws_ecr_repository.frontend[0].registry_id : null
}

# Models Repository Outputs
output "models_repository_arn" {
  description = "ARN of the Models ECR repository"
  value       = var.create_models_repository ? aws_ecr_repository.models[0].arn : null
}

output "models_repository_name" {
  description = "Name of the Models ECR repository"
  value       = var.create_models_repository ? aws_ecr_repository.models[0].name : null
}

output "models_repository_url" {
  description = "URL of the Models ECR repository"
  value       = var.create_models_repository ? aws_ecr_repository.models[0].repository_url : null
}

output "models_registry_id" {
  description = "Registry ID where the Models repository was created"
  value       = var.create_models_repository ? aws_ecr_repository.models[0].registry_id : null
}

# Keycloak Repository Outputs
output "keycloak_repository_arn" {
  description = "ARN of the Keycloak ECR repository"
  value       = var.create_keycloak_repository ? aws_ecr_repository.keycloak[0].arn : null
}

output "keycloak_repository_name" {
  description = "Name of the Keycloak ECR repository"
  value       = var.create_keycloak_repository ? aws_ecr_repository.keycloak[0].name : null
}

output "keycloak_repository_url" {
  description = "URL of the Keycloak ECR repository"
  value       = var.create_keycloak_repository ? aws_ecr_repository.keycloak[0].repository_url : null
}

output "keycloak_registry_id" {
  description = "Registry ID where the Keycloak repository was created"
  value       = var.create_keycloak_repository ? aws_ecr_repository.keycloak[0].registry_id : null
}

# Consolidated Outputs
output "repository_urls" {
  description = "Map of all repository URLs"
  value = {
    api      = var.create_api_repository ? aws_ecr_repository.api[0].repository_url : null
    frontend = var.create_frontend_repository ? aws_ecr_repository.frontend[0].repository_url : null
    models   = var.create_models_repository ? aws_ecr_repository.models[0].repository_url : null
    keycloak = var.create_keycloak_repository ? aws_ecr_repository.keycloak[0].repository_url : null
  }
}

output "repository_arns" {
  description = "Map of all repository ARNs"
  value = {
    api      = var.create_api_repository ? aws_ecr_repository.api[0].arn : null
    frontend = var.create_frontend_repository ? aws_ecr_repository.frontend[0].arn : null
    models   = var.create_models_repository ? aws_ecr_repository.models[0].arn : null
    keycloak = var.create_keycloak_repository ? aws_ecr_repository.keycloak[0].arn : null
  }
}

output "repository_names" {
  description = "Map of all repository names"
  value = {
    api      = var.create_api_repository ? aws_ecr_repository.api[0].name : null
    frontend = var.create_frontend_repository ? aws_ecr_repository.frontend[0].name : null
    models   = var.create_models_repository ? aws_ecr_repository.models[0].name : null
    keycloak = var.create_keycloak_repository ? aws_ecr_repository.keycloak[0].name : null
  }
}

# Registry Information
output "ecr_registry_id" {
  description = "ECR registry ID (same for all repositories in the account)"
  value = var.create_api_repository ? aws_ecr_repository.api[0].registry_id : (
    var.create_frontend_repository ? aws_ecr_repository.frontend[0].registry_id : (
      var.create_models_repository ? aws_ecr_repository.models[0].registry_id : (
        var.create_keycloak_repository ? aws_ecr_repository.keycloak[0].registry_id : null
      )
    )
  )
}

# Lifecycle Policy Information
output "lifecycle_policies_applied" {
  description = "Map indicating which repositories have lifecycle policies applied"
  value = {
    api      = var.create_api_repository
    frontend = var.create_frontend_repository
    models   = var.create_models_repository
    keycloak = var.create_keycloak_repository
  }
}

# GitHub Actions Access Information
output "github_actions_access_enabled" {
  description = "Whether GitHub Actions access is enabled (repository policies applied)"
  value       = length(var.github_actions_principals) > 0
}
