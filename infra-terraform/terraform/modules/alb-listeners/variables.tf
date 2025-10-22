# =============================================================================
# ALB Listeners Module Variables
# =============================================================================
# Description: Variables for creating ALB listeners with HTTP redirect and HTTPS forwarding

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

variable "load_balancer_arn" {
  description = "ARN of the Application Load Balancer"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:elasticloadbalancing:", var.load_balancer_arn))
    error_message = "Load balancer ARN must be a valid AWS ELB ARN."
  }
}

variable "target_group_arn" {
  description = "ARN of the target group for HTTPS forwarding"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:elasticloadbalancing:", var.target_group_arn))
    error_message = "Target group ARN must be a valid AWS ELB target group ARN."
  }
}

variable "certificate_arn" {
  description = "ARN of the SSL/TLS certificate for HTTPS listener"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:(acm|iam):", var.certificate_arn))
    error_message = "Certificate ARN must be a valid AWS ACM or IAM certificate ARN."
  }
}

variable "ssl_policy" {
  description = "SSL policy for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"

  validation {
    condition     = can(regex("^ELBSecurityPolicy-", var.ssl_policy))
    error_message = "SSL policy must be a valid ELB security policy."
  }
}

variable "http_port" {
  description = "Port for HTTP listener (for redirect)"
  type        = number
  default     = 80

  validation {
    condition     = var.http_port > 0 && var.http_port <= 65535
    error_message = "HTTP port must be between 1 and 65535."
  }
}

variable "https_port" {
  description = "Port for HTTPS listener"
  type        = number
  default     = 443

  validation {
    condition     = var.https_port > 0 && var.https_port <= 65535
    error_message = "HTTPS port must be between 1 and 65535."
  }
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}
