# =============================================================================
# CFGI CLIENT TERRAFORM VARIABLES
# =============================================================================
# 
# Input variables for CFGI client infrastructure deployment.
# Sensitive values should be provided via secrets.tfvars file.
#
# Usage:
#   terraform apply -var-file="secrets.tfvars"
#
# =============================================================================

# =============================================================================
# AWS CONFIGURATION VARIABLES
# =============================================================================

variable "aws_account_id" {
  description = "AWS Account ID for CFGI (required for IAM roles and other AWS-specific resources)"
  type        = string
  sensitive   = true
  default     = "" # Optional - will be required when deploying IAM roles

  validation {
    condition     = var.aws_account_id == "" || can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "AWS Account ID must be a 12-digit number or empty string."
  }
}

# =============================================================================
# KIMBALL PRODUCT VARIABLES
# =============================================================================

variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "kainamAI"
}

variable "kimball_frontend_repo" {
  description = "GitHub repository name for Kimball frontend"
  type        = string
  default     = "kimball-frontend"
}

variable "kimball_api_repo" {
  description = "GitHub repository name for Kimball API"
  type        = string
  default     = "kimball-fastapi"
}

variable "kimball_github_repositories" {
  description = "List of GitHub repositories for Kimball CI/CD (deprecated - use individual repo variables)"
  type        = list(string)
  default     = ["kimball-frontend", "kimball-fastapi"]
}

variable "kimball_github_branch" {
  description = "GitHub branch to deploy from"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "main", "staging"], var.kimball_github_branch)
    error_message = "GitHub branch must be one of: dev, main, staging."
  }
}

variable "github_connection_arn" {
  description = "ARN of the AWS CodeStar connection to GitHub for CI/CD pipelines"
  type        = string
  default     = "arn:aws:codeconnections:us-east-2:335082366169:connection/2bc5f055-729b-47e8-bca9-dbbf86bc2a75"
  sensitive   = true
}

variable "kimball_frontend_cpu" {
  description = "CPU units for Kimball frontend App Runner service (1024 = 1 vCPU)"
  type        = number
  default     = 1024

  validation {
    condition     = contains([1024, 2048, 4096], var.kimball_frontend_cpu)
    error_message = "CPU must be 1024, 2048, or 4096."
  }
}

variable "kimball_frontend_memory" {
  description = "Memory (MB) for Kimball frontend App Runner service"
  type        = number
  default     = 2048

  validation {
    condition     = contains([2048, 3072, 4096, 8192, 12288], var.kimball_frontend_memory)
    error_message = "Memory must be 2048, 3072, 4096, 8192, or 12288 MB."
  }
}

variable "kimball_backend_cpu" {
  description = "CPU units for Kimball backend App Runner service (1024 = 1 vCPU)"
  type        = number
  default     = 1024

  validation {
    condition     = contains([1024, 2048, 4096], var.kimball_backend_cpu)
    error_message = "CPU must be 1024, 2048, or 4096."
  }
}

variable "kimball_backend_memory" {
  description = "Memory (MB) for Kimball backend App Runner service"
  type        = number
  default     = 2048

  validation {
    condition     = contains([2048, 3072, 4096, 8192, 12288], var.kimball_backend_memory)
    error_message = "Memory must be 2048, 3072, 4096, 8192, or 12288 MB."
  }
}

# =============================================================================
# ECR CONFIGURATION VARIABLES
# =============================================================================

variable "ecr_image_retention_count" {
  description = "Number of images to retain in ECR repositories"
  type        = number
  default     = 10

  validation {
    condition     = var.ecr_image_retention_count > 0 && var.ecr_image_retention_count <= 100
    error_message = "ECR image retention count must be between 1 and 100."
  }
}

variable "ecr_enable_image_scanning" {
  description = "Enable image vulnerability scanning on push for ECR repositories"
  type        = bool
  default     = true
}

variable "ecr_repository_encryption_type" {
  description = "Encryption type for ECR repositories"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.ecr_repository_encryption_type)
    error_message = "ECR repository encryption type must be either AES256 or KMS."
  }
}

# =============================================================================
# CODEPIPELINE CONFIGURATION VARIABLES
# =============================================================================

variable "codepipeline_build_timeout" {
  description = "CodeBuild timeout in minutes"
  type        = number
  default     = 60

  validation {
    condition     = var.codepipeline_build_timeout >= 5 && var.codepipeline_build_timeout <= 480
    error_message = "Build timeout must be between 5 and 480 minutes."
  }
}

# =============================================================================
# MONZA PRODUCT VARIABLES (PLACEHOLDER)
# =============================================================================
# These variables will be uncommented and configured when Monza specifications
# are provided by the client.

# variable "monza_instance_type" {
#   description = "EC2 instance type for Monza (ClickHouse + Airflow)"
#   type        = string
#   default     = "m5.xlarge"
# }

# variable "monza_root_volume_size" {
#   description = "Root volume size in GB for Monza EC2 instance"
#   type        = number
#   default     = 50
# }

# variable "monza_ssh_public_key" {
#   description = "SSH public key for Monza EC2 instance access"
#   type        = string
#   sensitive   = true
# }
