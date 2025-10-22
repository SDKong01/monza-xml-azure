# ===================================
# Common Variables
# ===================================

variable "environment" {
  description = "Environment name (dev, uat, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, uat, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "kainam"
}

variable "service_name" {
  description = "Name of the service"
  type        = string
  default     = "senna"
  validation {
    condition     = length(var.service_name) > 0 && length(var.service_name) <= 32
    error_message = "Service name must be between 1 and 32 characters."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ===================================
# GitHub Actions OIDC Configuration
# ===================================

variable "create_github_oidc_provider" {
  description = "Whether to create the GitHub OIDC provider"
  type        = bool
  default     = true
}

variable "create_github_oidc_role" {
  description = "Whether to create the GitHub Actions OIDC role for ECR access"
  type        = bool
  default     = true
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = ""
}

variable "github_repositories" {
  description = "List of GitHub repositories that can assume the role"
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.github_repositories) > 0 || var.create_github_oidc_role == false
    error_message = "At least one GitHub repository must be specified when creating GitHub OIDC role."
  }
}

variable "github_branches" {
  description = "List of GitHub branches that can assume the role"
  type        = list(string)
  default     = ["main", "develop"]
}

variable "ecr_repository_arns" {
  description = "List of ECR repository ARNs that GitHub Actions can push to"
  type        = list(string)
  default     = []
}

# ===================================
# App Runner Configuration
# ===================================

variable "create_app_runner_access_role" {
  description = "Whether to create the App Runner access role for ECR"
  type        = bool
  default     = true
}

variable "create_app_runner_instance_role" {
  description = "Whether to create the App Runner instance role for application permissions"
  type        = bool
  default     = true
}

variable "app_runner_additional_policies" {
  description = "Additional IAM policy ARNs to attach to App Runner instance role"
  type        = list(string)
  default     = []
}

# ===================================
# EC2 Configuration
# ===================================

variable "create_ec2_instance_role" {
  description = "Whether to create the EC2 instance role and profile"
  type        = bool
  default     = true
}

variable "create_ec2_worker_role" {
  description = "Whether to create the EC2 worker role with ECR access"
  type        = bool
  default     = true
}

variable "ec2_additional_policies" {
  description = "Additional IAM policy ARNs to attach to EC2 instance role"
  type        = list(string)
  default     = []
}

# ===================================
# Secrets Manager Configuration
# ===================================

variable "secrets_manager_secret_arns" {
  description = "List of Secrets Manager secret ARNs that roles can access"
  type        = list(string)
  default     = []
}

# ===================================
# ElastiCache Configuration
# ===================================

variable "elasticache_cluster_arn" {
  description = "ElastiCache cluster ARN for access permissions"
  type        = string
  default     = ""
}
