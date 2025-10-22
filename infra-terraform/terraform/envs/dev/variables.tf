# Variables for secrets (passed via secrets.tfvars)
variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  sensitive   = true
}

variable "senna_ec2_ssh_public_key" {
  description = "SSH public key for SENNA EC2 instances"
  type        = string
  sensitive   = true
}

variable "keycloak_ssh_public_key" {
  description = "SSH public key for Keycloak EC2 instance (dedicated key for maintenance access)"
  type        = string
  sensitive   = true
}

variable "rds_username" {
  description = "Username for the RDS database"
  type        = string
  sensitive   = true
}

variable "rds_password" {
  description = "Password for the RDS database"
  type        = string
  sensitive   = true
}

variable "keycloak_username" {
  description = "Username for the Keycloak admin secret"
  type        = string
  sensitive   = true
}

variable "keycloak_password" {
  description = "Password for the Keycloak admin secret"
  type        = string
  sensitive   = true
}

variable "senna_backend_client_secret" {
  description = "Client secret for the SENNA backend service from Keycloak"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.senna_backend_client_secret) >= 16
    error_message = "SENNA backend client secret must be at least 16 characters long."
  }

  validation {
    condition     = can(regex("^[A-Za-z0-9]+$", var.senna_backend_client_secret))
    error_message = "SENNA backend client secret must contain only letters and numbers."
  }
}

# ===================================
# SENNA ECR Configuration Variables
# ===================================

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

variable "ecr_github_actions_principals" {
  description = "List of GitHub Actions principal ARNs that can push to ECR repositories"
  type        = list(string)
  default     = []
}

# ===================================
# SENNA ElastiCache Configuration Variables
# ===================================

variable "elasticache_engine_version" {
  description = "Engine version for ElastiCache Redis cluster"
  type        = string
  default     = "7.0"
}

variable "elasticache_node_type" {
  description = "Node type for ElastiCache cluster"
  type        = string
  default     = "cache.t4g.small"
}

variable "elasticache_subnet_ids" {
  description = "List of subnet IDs for ElastiCache cluster"
  type        = list(string)
  default = [
    "subnet-075d92a295819c6d1", # kainam-dev-private-subnet-a
    "subnet-0f90eb51114680321"  # kainam-dev-public-subnet-b
  ]
}

variable "elasticache_at_rest_encryption_enabled" {
  description = "Enable encryption at rest for ElastiCache"
  type        = bool
  default     = true
}

variable "elasticache_transit_encryption_enabled" {
  description = "Enable encryption in transit for ElastiCache"
  type        = bool
  default     = true
}

variable "elasticache_auth_token" {
  description = "Auth token for Redis (required when transit encryption is enabled)"
  type        = string
  default     = "N4p7Xq2B9d6L1yF3"
  sensitive   = true
}

variable "elasticache_maintenance_window" {
  description = "Maintenance window for ElastiCache updates"
  type        = string
  default     = "sun:05:00-sun:09:00"
}

variable "elasticache_apply_immediately" {
  description = "Apply ElastiCache changes immediately or during maintenance window"
  type        = bool
  default     = false
}

variable "elasticache_auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades for ElastiCache"
  type        = bool
  default     = true
}

variable "elasticache_snapshot_retention_limit" {
  description = "Number of days to retain ElastiCache snapshots (0-35)"
  type        = number
  default     = 5
  validation {
    condition     = var.elasticache_snapshot_retention_limit >= 0 && var.elasticache_snapshot_retention_limit <= 35
    error_message = "ElastiCache snapshot retention limit must be between 0 and 35 days."
  }
}

variable "elasticache_snapshot_window" {
  description = "Daily snapshot window for ElastiCache in UTC"
  type        = string
  default     = "03:00-05:00"
}

variable "elasticache_final_snapshot_identifier" {
  description = "Name of final snapshot when ElastiCache cluster is deleted"
  type        = string
  default     = null
}

variable "elasticache_parameter_group_family" {
  description = "Parameter group family for ElastiCache"
  type        = string
  default     = "redis7"
}

variable "elasticache_parameters" {
  description = "List of parameters to apply to ElastiCache parameter group"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "maxmemory-policy"
      value = "allkeys-lru"
    }
  ]
}

# ===================================
# SENNA IAM Roles Configuration Variables
# ===================================

variable "iam_create_github_oidc_provider" {
  description = "Whether to create the GitHub OIDC provider"
  type        = bool
  default     = true
}

variable "iam_create_github_oidc_role" {
  description = "Whether to create the GitHub Actions OIDC role for ECR access"
  type        = bool
  default     = true
}

variable "iam_github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "your-github-org"
}

variable "iam_github_repositories" {
  description = "List of GitHub repositories that can assume the role"
  type        = list(string)
  default = [
    "ezml-fastapi",
    "ezml-frontend",
    "senna"
  ]
}

variable "iam_github_branches" {
  description = "List of GitHub branches that can assume the role"
  type        = list(string)
  default     = ["main", "develop"]
}

variable "iam_create_app_runner_access_role" {
  description = "Whether to create the App Runner access role for ECR"
  type        = bool
  default     = true
}

variable "iam_create_app_runner_instance_role" {
  description = "Whether to create the App Runner instance role for application permissions"
  type        = bool
  default     = true
}

variable "iam_app_runner_additional_policies" {
  description = "Additional IAM policy ARNs to attach to App Runner instance role"
  type        = list(string)
  default     = []
}

variable "iam_create_ec2_instance_role" {
  description = "Whether to create the EC2 instance role and profile"
  type        = bool
  default     = true
}

variable "iam_create_ec2_worker_role" {
  description = "Whether to create the EC2 worker role with ECR access"
  type        = bool
  default     = true
}

variable "iam_ec2_additional_policies" {
  description = "Additional IAM policy ARNs to attach to EC2 instance role"
  type        = list(string)
  default     = []
}

variable "iam_secrets_manager_secret_arns" {
  description = "List of Secrets Manager secret ARNs that roles can access"
  type        = list(string)
  default     = []
}

# ===================================
# SENNA API Configuration Variables
# ===================================

variable "openai_api_key" {
  description = "OpenAI API key for SENNA application"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^sk-", var.openai_api_key))
    error_message = "OpenAI API key must start with 'sk-'."
  }
}

# ===================================
# SENNA Frontend Configuration Variables
# ===================================

variable "senna_base_secret" {
  description = "Base secret for SENNA frontend authentication (stored in secrets.tfvars)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.senna_base_secret) >= 32
    error_message = "BASE_SECRET must be at least 32 characters long for security."
  }
}

variable "senna_api_base_url" {
  description = "Base URL for the SENNA API backend (App Runner service URL)"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^https://.*\\.awsapprunner\\.com$", var.senna_api_base_url))
    error_message = "SENNA API base URL must be a valid HTTPS AWS App Runner URL."
  }
}

# ===================================
# SENNA CodePipeline Configuration Variables
# ===================================

variable "codepipeline_create_frontend_pipeline" {
  description = "Whether to create the frontend CodePipeline"
  type        = bool
  default     = true
}

variable "codepipeline_create_api_pipeline" {
  description = "Whether to create the API CodePipeline"
  type        = bool
  default     = true
}

variable "codepipeline_create_models_pipeline" {
  description = "Whether to create the models CodePipeline"
  type        = bool
  default     = true
}

variable "codepipeline_create_keycloak_pipeline" {
  description = "Whether to create the Keycloak authentication CodePipeline"
  type        = bool
  default     = true
}

variable "codepipeline_source_branch" {
  description = "Git branch to trigger CodePipeline"
  type        = string
  default     = "dev"
}

variable "codepipeline_build_timeout" {
  description = "CodeBuild timeout in minutes"
  type        = number
  default     = 60
  validation {
    condition     = var.codepipeline_build_timeout >= 5 && var.codepipeline_build_timeout <= 480
    error_message = "Build timeout must be between 5 and 480 minutes."
  }
}

variable "codepipeline_create_kainam_platform_api_pipeline" {
  description = "Whether to create the Kainam Platform API pipeline"
  type        = bool
  default     = true
}

variable "codepipeline_create_kainam_platform_frontend_pipeline" {
  description = "Whether to create the Kainam Platform frontend pipeline"
  type        = bool
  default     = true
}