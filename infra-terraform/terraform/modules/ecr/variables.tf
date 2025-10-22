# ECR Module Variables
# Terraform module for managing AWS Elastic Container Registry (ECR) repositories

variable "environment" {
  description = "Environment name (e.g., dev, uat, prod)"
  type        = string
  validation {
    condition     = can(regex("^(dev|uat|prod)$", var.environment))
    error_message = "Environment must be one of: dev, uat, prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name))
    error_message = "Project name must start with a letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number."
  }
}

variable "service_name" {
  description = "Service name for ECR repository naming (e.g., senna, kainam-platform, kimball)"
  type        = string
  default     = "senna"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.service_name))
    error_message = "Service name must start with a letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number."
  }
}

variable "create_api_repository" {
  description = "Whether to create the API ECR repository"
  type        = bool
  default     = true
}

variable "create_frontend_repository" {
  description = "Whether to create the Frontend ECR repository"
  type        = bool
  default     = true
}

variable "create_models_repository" {
  description = "Whether to create the Models ECR repository"
  type        = bool
  default     = true
}

variable "create_keycloak_repository" {
  description = "Whether to create the Keycloak ECR repository"
  type        = bool
  default     = false
}

variable "image_retention_count" {
  description = "Number of images to retain in the repository (lifecycle policy)"
  type        = number
  default     = 10
  validation {
    condition     = var.image_retention_count > 0 && var.image_retention_count <= 100
    error_message = "Image retention count must be between 1 and 100."
  }
}

variable "enable_image_scan_on_push" {
  description = "Enable image scanning on push to repositories"
  type        = bool
  default     = true
}

variable "repository_encryption_type" {
  description = "Encryption type for ECR repositories"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "KMS"], var.repository_encryption_type)
    error_message = "Repository encryption type must be either AES256 or KMS."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for repository encryption (required if encryption_type is KMS)"
  type        = string
  default     = null
}

variable "github_actions_principals" {
  description = "List of GitHub Actions principal ARNs that can push to ECR repositories"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
