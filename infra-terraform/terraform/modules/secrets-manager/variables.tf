variable "project_name" {
  description = "Name of the project for resource naming and tagging"
  type        = string
  default     = "keystone"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "rds_username" {
  description = "Username for the RDS database secret"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "rds_password" {
  description = "Password for the RDS database secret"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.rds_password) >= 16
    error_message = "RDS password must be at least 16 characters long."
  }

  validation {
    condition     = can(regex("^[A-Za-z0-9]+$", var.rds_password))
    error_message = "RDS password must contain only letters and numbers."
  }
}

variable "keycloak_username" {
  description = "Username for the Keycloak admin secret"
  type        = string
  default     = "admin-cli"
  sensitive   = true
}

variable "keycloak_password" {
  description = "Password for the Keycloak admin secret"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.keycloak_password) >= 16
    error_message = "Keycloak password must be at least 16 characters long."
  }

  validation {
    condition     = can(regex("^[A-Za-z0-9]+$", var.keycloak_password))
    error_message = "Keycloak password must contain only letters and numbers."
  }
}

variable "kms_key_id" {
  description = "KMS key ID for encrypting secrets (optional - uses AWS managed key if not provided)"
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Number of days to retain deleted secrets for recovery"
  type        = number
  default     = 7

  validation {
    condition     = var.recovery_window_in_days >= 0 && var.recovery_window_in_days <= 30
    error_message = "Recovery window must be between 0 and 30 days."
  }
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

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
