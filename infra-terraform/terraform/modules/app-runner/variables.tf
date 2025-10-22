# ===================================
# App Runner Module - Variables
# ===================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, uat, prod)"
  type        = string
}

variable "service_name" {
  description = "Name of the App Runner service"
  type        = string
}

# ===================================
# ECR Configuration
# ===================================

variable "ecr_repository_url" {
  description = "URL of the ECR repository containing the container image"
  type        = string
}

variable "image_tag" {
  description = "Tag of the container image to deploy"
  type        = string
  default     = "latest"
}

# ===================================
# App Configuration
# ===================================

variable "port" {
  description = "Port that the application listens on"
  type        = string
  default     = "8080"
}

variable "cpu" {
  description = "Number of CPU units (0.25 vCPU, 0.5 vCPU, 1 vCPU, 2 vCPU, 4 vCPU)"
  type        = string
  default     = "1024"

  validation {
    condition     = contains(["256", "512", "1024", "2048", "4096"], var.cpu)
    error_message = "CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "memory" {
  description = "Amount of memory in MB (512, 1024, 2048, 3072, 4096, 6144, 8192, 10240, 12288)"
  type        = string
  default     = "2048"

  validation {
    condition     = contains(["512", "1024", "2048", "3072", "4096", "6144", "8192", "10240", "12288"], var.memory)
    error_message = "Memory must be one of: 512, 1024, 2048, 3072, 4096, 6144, 8192, 10240, 12288."
  }
}

# ===================================
# Environment Variables
# ===================================

variable "environment_variables" {
  description = "Map of environment variables for the application"
  type        = map(string)
  default     = {}
}

variable "environment_secrets" {
  description = "Map of environment secrets (ARNs from Secrets Manager or SSM Parameter Store)"
  type        = map(string)
  default     = {}
}

# ===================================
# IAM Configuration
# ===================================

variable "access_role_arn" {
  description = "ARN of the IAM role that grants App Runner access to ECR"
  type        = string
}

variable "instance_role_arn" {
  description = "ARN of the IAM role that provides permissions to the running application"
  type        = string
}

# ===================================
# Network Configuration
# ===================================

variable "is_publicly_accessible" {
  description = "Whether the App Runner service is publicly accessible"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "ID of the VPC where resources will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the VPC connector"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID must be provided."
  }
}

variable "create_vpc_connector" {
  description = "Whether to create a VPC connector for private network access"
  type        = bool
  default     = true
}

# ===================================
# Health Check Configuration
# ===================================

variable "health_check_enabled" {
  description = "Whether to enable health checks"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "Path for health check requests"
  type        = string
  default     = "/"
}

variable "health_check_protocol" {
  description = "Protocol for health checks (TCP or HTTP)"
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["TCP", "HTTP"], var.health_check_protocol)
    error_message = "Health check protocol must be TCP or HTTP."
  }
}

variable "health_check_interval" {
  description = "Interval between health checks in seconds (1-20)"
  type        = number
  default     = 5

  validation {
    condition     = var.health_check_interval >= 1 && var.health_check_interval <= 20
    error_message = "Health check interval must be between 1 and 20 seconds."
  }
}

variable "health_check_timeout" {
  description = "Timeout for health check response in seconds (1-20)"
  type        = number
  default     = 2

  validation {
    condition     = var.health_check_timeout >= 1 && var.health_check_timeout <= 20
    error_message = "Health check timeout must be between 1 and 20 seconds."
  }
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful checks for healthy status (1-20)"
  type        = number
  default     = 1

  validation {
    condition     = var.health_check_healthy_threshold >= 1 && var.health_check_healthy_threshold <= 20
    error_message = "Health check healthy threshold must be between 1 and 20."
  }
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed checks for unhealthy status (1-20)"
  type        = number
  default     = 5

  validation {
    condition     = var.health_check_unhealthy_threshold >= 1 && var.health_check_unhealthy_threshold <= 20
    error_message = "Health check unhealthy threshold must be between 1 and 20."
  }
}

# ===================================
# Auto Deployment
# ===================================

variable "auto_deployments_enabled" {
  description = "Whether to enable automatic deployments from ECR"
  type        = bool
  default     = true
}

# ===================================
# Common Tags
# ===================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ===================================
# Custom Domain Configuration
# ===================================

variable "enable_custom_domain" {
  description = "Whether to enable custom domain for the App Runner service"
  type        = bool
  default     = false
}

variable "custom_domain_name" {
  description = "Custom domain name for the App Runner service (e.g., 'senna-dev.kainam.app')"
  type        = string
  default     = ""

  validation {
    condition     = var.enable_custom_domain == false || (var.enable_custom_domain == true && length(var.custom_domain_name) > 0)
    error_message = "custom_domain_name must be provided when enable_custom_domain is true."
  }
}

variable "domain_certificate_arn" {
  description = "ARN of the ACM certificate for the custom domain"
  type        = string
  default     = ""

  validation {
    condition     = var.enable_custom_domain == false || (var.enable_custom_domain == true && length(var.domain_certificate_arn) > 0)
    error_message = "domain_certificate_arn must be provided when enable_custom_domain is true."
  }
}