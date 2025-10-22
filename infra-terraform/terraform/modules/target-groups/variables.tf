# =============================================================================
# Target Groups Module Variables
# =============================================================================
# Description: Variables for creating and managing ALB/NLB target groups

variable "environment" {
  description = "Environment identifier (dev, uat, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, uat, prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 20
    error_message = "Project name must be between 1 and 20 characters."
  }
}

variable "vpc_id" {
  description = "VPC ID where the target groups will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC identifier."
  }
}

variable "create_keycloak_target_group" {
  description = "Whether to create the Keycloak target group"
  type        = bool
  default     = true
}

variable "keycloak_target_port" {
  description = "Port on which Keycloak instances receive traffic"
  type        = number
  default     = 8080

  validation {
    condition     = var.keycloak_target_port > 0 && var.keycloak_target_port <= 65535
    error_message = "Target port must be between 1 and 65535."
  }
}

variable "keycloak_health_check_path" {
  description = "Health check path for Keycloak instances"
  type        = string
  default     = "/health/ready"

  validation {
    condition     = can(regex("^/.*", var.keycloak_health_check_path))
    error_message = "Health check path must start with '/'."
  }
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}
