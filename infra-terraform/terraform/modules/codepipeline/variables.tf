# ===================================
# Core Variables
# ===================================

variable "environment" {
  description = "Environment name (e.g., dev, uat, prod)"
  type        = string
  validation {
    condition     = can(regex("^(dev|uat|prod)$", var.environment))
    error_message = "Environment must be dev, uat, or prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "kainam"
}

variable "service_name" {
  description = "Service name (e.g., senna)"
  type        = string
  default     = "senna"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.service_name))
    error_message = "Service name must be lowercase alphanumeric with hyphens."
  }
}

# ===================================
# CodePipeline Configuration
# ===================================

variable "create_frontend_pipeline" {
  description = "Whether to create the frontend pipeline"
  type        = bool
  default     = true
}

variable "create_api_pipeline" {
  description = "Whether to create the API pipeline"
  type        = bool
  default     = true
}

variable "create_models_pipeline" {
  description = "Whether to create the models pipeline"
  type        = bool
  default     = true
}

variable "create_keycloak_pipeline" {
  description = "Whether to create the Keycloak authentication pipeline"
  type        = bool
  default     = false
}

variable "create_kainam_platform_api_pipeline" {
  description = "Whether to create the Kainam Platform API pipeline"
  type        = bool
  default     = false
}

variable "create_kainam_platform_frontend_pipeline" {
  description = "Whether to create the Kainam Platform frontend pipeline"
  type        = bool
  default     = false
}

variable "github_connection_arn" {
  description = "ARN of the GitHub connection for CodeStar"
  type        = string
  default     = "arn:aws:codeconnections:us-east-2:592172380963:connection/3ad369cc-5a95-45da-876e-fce3cb9b8a8a"
}

variable "source_branch" {
  description = "Git branch to trigger pipeline"
  type        = string
  default     = "DEV"
}

# ===================================
# Repository Configuration
# ===================================

variable "frontend_repository" {
  description = "GitHub repository for frontend (format: org/repo)"
  type        = string
  default     = "kainamAI/ezml-frontend"
}

variable "api_repository" {
  description = "GitHub repository for API (format: org/repo)"
  type        = string
  default     = "kainamAI/ezml-fastapi"
}

variable "models_repository" {
  description = "GitHub repository for models (format: org/repo)"
  type        = string
  default     = "kainamAI/senna"
}

variable "keycloak_repository" {
  description = "GitHub repository for Keycloak authentication (format: org/repo)"
  type        = string
  default     = "kainamAI/kainam-backend"
}

variable "kainam_platform_api_repository" {
  description = "GitHub repository for Kainam Platform API (format: org/repo)"
  type        = string
  default     = "kainamAI/kainam-backend"
}

variable "kainam_platform_frontend_repository" {
  description = "GitHub repository for Kainam Platform frontend (format: org/repo)"
  type        = string
  default     = "kainamAI/kainam-front"
}

# ===================================
# ECR Configuration
# ===================================

variable "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  type = object({
    frontend = string
    api      = string
    models   = string
  })
}

variable "ecr_registry_id" {
  description = "ECR registry ID (AWS account ID)"
  type        = string
}

variable "kainam_platform_ecr_repository_urls" {
  description = "Map of Kainam Platform ECR repository URLs"
  type = object({
    api      = string
    frontend = string
  })
  default = {
    api      = ""
    frontend = ""
  }
}

# ===================================
# CodeBuild Configuration
# ===================================

variable "codebuild_compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
  validation {
    condition = contains([
      "BUILD_GENERAL1_SMALL",
      "BUILD_GENERAL1_MEDIUM",
      "BUILD_GENERAL1_LARGE"
    ], var.codebuild_compute_type)
    error_message = "CodeBuild compute type must be SMALL, MEDIUM, or LARGE."
  }
}

variable "codebuild_image" {
  description = "CodeBuild Docker image"
  type        = string
  default     = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
}

variable "build_timeout" {
  description = "Build timeout in minutes"
  type        = number
  default     = 60
  validation {
    condition     = var.build_timeout >= 5 && var.build_timeout <= 480
    error_message = "Build timeout must be between 5 and 480 minutes."
  }
}

# ===================================
# Environment Variables for Builds
# ===================================

variable "frontend_environment_variables" {
  description = "Environment variables for frontend build"
  type = list(object({
    name  = string
    value = string
    type  = string
  }))
  default = []
}

variable "api_environment_variables" {
  description = "Environment variables for API build"
  type = list(object({
    name  = string
    value = string
    type  = string
  }))
  default = []
}

variable "models_environment_variables" {
  description = "Environment variables for models build"
  type = list(object({
    name  = string
    value = string
    type  = string
  }))
  default = []
}

variable "kainam_platform_api_environment_variables" {
  description = "Environment variables for Kainam Platform API build"
  type = list(object({
    name  = string
    value = string
    type  = string
  }))
  default = []
}

variable "kainam_platform_frontend_environment_variables" {
  description = "Environment variables for Kainam Platform frontend build"
  type = list(object({
    name  = string
    value = string
    type  = string
  }))
  default = []
}

# ===================================
# Common Tags
# ===================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
