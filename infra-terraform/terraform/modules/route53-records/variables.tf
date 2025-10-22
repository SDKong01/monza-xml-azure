# =============================================================================
# Route 53 Records Module Variables
# =============================================================================
# Description: Variables for creating Route 53 DNS records, including ALB alias records

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

# Authentication ALB DNS Configuration
variable "create_auth_dns_record" {
  description = "Whether to create the authentication ALB DNS record"
  type        = bool
  default     = true
}

variable "auth_subdomain" {
  description = "Subdomain for the authentication service (e.g., 'auth' for auth.dev.kainam.app)"
  type        = string
  default     = "auth"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.auth_subdomain))
    error_message = "Subdomain must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "base_domain" {
  description = "Base domain for DNS records (e.g., 'dev.kainam.app')"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.base_domain))
    error_message = "Base domain must be a valid domain name."
  }
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string

  # validation {
  #   condition     = can(regex("^[a-zA-Z0-9.-]+\\.elb\\.[a-zA-Z0-9-]+\\.amazonaws\\.com$", var.alb_dns_name))
  #   error_message = "ALB DNS name must be a valid AWS ELB DNS name."
  # }
}

variable "alb_zone_id" {
  description = "Hosted zone ID of the Application Load Balancer"
  type        = string

  validation {
    condition     = can(regex("^Z[A-Z0-9]+$", var.alb_zone_id))
    error_message = "ALB zone ID must be a valid AWS hosted zone ID."
  }
}

# Route 53 Hosted Zone Configuration
variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for the base domain"
  type        = string

  validation {
    condition     = can(regex("^Z[A-Z0-9]+$", var.hosted_zone_id))
    error_message = "Hosted zone ID must be a valid AWS hosted zone ID."
  }
}

variable "evaluate_target_health" {
  description = "Whether Route 53 should evaluate the health of the ALB target"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

# ===================================
# SENNA App Runner DNS Configuration
# ===================================

variable "create_senna_dns_record" {
  description = "Whether to create the SENNA App Runner DNS record"
  type        = bool
  default     = false
}

variable "senna_subdomain" {
  description = "Subdomain for the SENNA service (e.g., 'senna-dev' for senna-dev.kainam.app)"
  type        = string
  default     = "senna-dev"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.senna_subdomain))
    error_message = "Subdomain must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "senna_app_runner_url" {
  description = "App Runner service URL for SENNA frontend (without https://)"
  type        = string
  default     = ""

  validation {
    condition     = var.senna_app_runner_url == "" || can(regex("^[a-z0-9-]+\\.us-[a-z]+-[0-9]+\\.awsapprunner\\.com$", var.senna_app_runner_url))
    error_message = "App Runner URL must be a valid AWS App Runner URL format."
  }
}

# ===================================
# SENNA Certificate Validation Configuration
# ===================================

variable "create_senna_certificate_validation_records" {
  description = "Whether to create SENNA certificate validation DNS records"
  type        = bool
  default     = false
}

variable "senna_certificate_validation_records" {
  description = "List of certificate validation records for SENNA custom domain"
  type = list(object({
    name   = string
    type   = string
    value  = string
    status = string
  }))
  default = []

  validation {
    condition = alltrue([
      for record in var.senna_certificate_validation_records :
      record.type == "CNAME" && startswith(record.name, "_")
    ])
    error_message = "Certificate validation records must be CNAME records with names starting with underscore."
  }
}

# ===================================
# Kainam Platform App Runner DNS Configuration
# ===================================

variable "create_kainam_platform_dns_record" {
  description = "Whether to create the Kainam Platform App Runner DNS record"
  type        = bool
  default     = false
}

variable "kainam_platform_subdomain" {
  description = "Subdomain for the Kainam Platform service (e.g., 'kainam-console-dev' for kainam-console-dev.kainam.app)"
  type        = string
  default     = "kainam-console-dev"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.kainam_platform_subdomain))
    error_message = "Subdomain must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "kainam_platform_app_runner_url" {
  description = "App Runner service URL for Kainam Platform frontend (without https://)"
  type        = string
  default     = ""

  validation {
    condition     = var.kainam_platform_app_runner_url == "" || can(regex("^[a-z0-9.-]+\\.awsapprunner\\.com$", var.kainam_platform_app_runner_url))
    error_message = "App Runner URL must be a valid AWS App Runner domain or empty string."
  }
}