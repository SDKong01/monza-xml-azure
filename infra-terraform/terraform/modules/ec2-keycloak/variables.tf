# EC2 Keycloak Module Variables
# Provides Keycloak-specific EC2 instance configuration for authentication service deployment

# ===================================
# PROJECT CONFIGURATION
# ===================================

variable "project_name" {
  description = "Name of the project (used for resource naming and tagging)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, uat, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, uat, prod."
  }
}

# ===================================
# INSTANCE CONFIGURATION
# ===================================

variable "instance_type" {
  description = "EC2 instance type for Keycloak service"
  type        = string
  default     = "t3.medium"
  validation {
    condition     = can(regex("^[a-z][0-9][a-z]?\\.[a-z0-9]+$", var.instance_type))
    error_message = "Instance type must be a valid EC2 instance type format (e.g., t3.medium, c6i.xlarge)."
  }
}

variable "ami_id" {
  description = "AMI ID for the Keycloak EC2 instance (Ubuntu 22.04 LTS recommended)"
  type        = string
  default     = "ami-0cfde0ea8edd312d4"
  validation {
    condition     = can(regex("^ami-[0-9a-f]{8,17}$", var.ami_id))
    error_message = "AMI ID must be a valid format (ami-xxxxxxxx)."
  }
}

variable "key_pair_name" {
  description = "Name of the EC2 Key Pair for SSH access (optional, used if ssh_public_key is not provided)"
  type        = string
  default     = null
}

variable "enable_ssh_access" {
  description = "Enable SSH access to the Keycloak instance"
  type        = bool
  default     = false
}

variable "ssh_trusted_ip_ranges" {
  description = "List of IP ranges allowed for SSH access (CIDR format)"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for cidr in var.ssh_trusted_ip_ranges : can(cidrhost(cidr, 0))
    ])
    error_message = "All IP ranges must be valid CIDR blocks (e.g., 192.168.1.0/24, 10.0.0.1/32)."
  }
}

variable "ssh_public_key" {
  description = "SSH public key for dedicated Keycloak instance access (takes precedence over key_pair_name)"
  type        = string
  default     = null
  sensitive   = true
}

# ===================================
# NETWORK CONFIGURATION
# ===================================

variable "vpc_id" {
  description = "VPC ID where the Keycloak instance will be deployed"
  type        = string
  validation {
    condition     = can(regex("^vpc-[0-9a-f]{8,17}$", var.vpc_id))
    error_message = "VPC ID must be a valid format (vpc-xxxxxxxx)."
  }
}

variable "subnet_id" {
  description = "Private subnet ID where the Keycloak instance will be deployed"
  type        = string
  validation {
    condition     = can(regex("^subnet-[0-9a-f]{8,17}$", var.subnet_id))
    error_message = "Subnet ID must be a valid format (subnet-xxxxxxxx)."
  }
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with the instance (should be false for private subnet)"
  type        = bool
  default     = false
}

# ===================================
# SECURITY CONFIGURATION
# ===================================

variable "alb_security_group_id" {
  description = "Security Group ID of the ALB to allow traffic from"
  type        = string
  validation {
    condition     = can(regex("^sg-[0-9a-f]{8,17}$", var.alb_security_group_id))
    error_message = "Security Group ID must be a valid format (sg-xxxxxxxx)."
  }
}

variable "additional_security_group_ids" {
  description = "Additional security group IDs to attach to the instance"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for sg_id in var.additional_security_group_ids : can(regex("^sg-[0-9a-f]{8,17}$", sg_id))
    ])
    error_message = "All security group IDs must be valid format (sg-xxxxxxxx)."
  }
}

# ===================================
# KEYCLOAK CONFIGURATION
# ===================================

variable "keycloak_hostname" {
  description = "Hostname for Keycloak service (e.g., auth-dev.kainam.app)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.keycloak_hostname))
    error_message = "Keycloak hostname must be a valid domain name."
  }
}

variable "keycloak_http_port" {
  description = "HTTP port for Keycloak service"
  type        = number
  default     = 8080
  validation {
    condition     = var.keycloak_http_port >= 1024 && var.keycloak_http_port <= 65535
    error_message = "Keycloak HTTP port must be between 1024 and 65535."
  }
}

variable "container_name" {
  description = "Name of the Keycloak Docker container"
  type        = string
  default     = "keycloak"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.container_name))
    error_message = "Container name must contain only lowercase letters, numbers, and hyphens."
  }
}

# ===================================
# DATABASE CONFIGURATION
# ===================================

variable "rds_endpoint" {
  description = "RDS PostgreSQL endpoint for Keycloak database"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z0-9.-]+\\.rds\\.amazonaws\\.com(:[0-9]+)?$", var.rds_endpoint))
    error_message = "RDS endpoint must be a valid AWS RDS endpoint format (with optional port)."
  }
}

variable "database_name" {
  description = "Database name for Keycloak"
  type        = string
  default     = "keycloak"
  validation {
    condition     = can(regex("^[a-z0-9_]+$", var.database_name))
    error_message = "Database name must contain only lowercase letters, numbers, and underscores."
  }
}

variable "database_port" {
  description = "Database port for PostgreSQL"
  type        = number
  default     = 5432
  validation {
    condition     = var.database_port >= 1024 && var.database_port <= 65535
    error_message = "Database port must be between 1024 and 65535."
  }
}

# ===================================
# ECR CONFIGURATION
# ===================================

variable "ecr_repository_url" {
  description = "ECR repository URL for Keycloak Docker image"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}\\.dkr\\.ecr\\.[a-z0-9-]+\\.amazonaws\\.com/[a-z0-9-]+$", var.ecr_repository_url))
    error_message = "ECR repository URL must be a valid AWS ECR format."
  }
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.image_tag))
    error_message = "Image tag must contain only alphanumeric characters, dots, underscores, and hyphens."
  }
}

# ===================================
# SECRETS MANAGER CONFIGURATION
# ===================================

variable "database_secret_name" {
  description = "AWS Secrets Manager secret name for database credentials"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9/_+=.@-]+$", var.database_secret_name))
    error_message = "Secret name must contain only valid AWS Secrets Manager characters."
  }
}

variable "keycloak_secret_name" {
  description = "AWS Secrets Manager secret name for Keycloak admin credentials"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9/_+=.@-]+$", var.keycloak_secret_name))
    error_message = "Secret name must contain only valid AWS Secrets Manager characters."
  }
}

# ===================================
# IAM CONFIGURATION
# ===================================

variable "create_iam_role" {
  description = "Whether to create a new IAM role for the Keycloak instance"
  type        = bool
  default     = true
}

variable "existing_iam_instance_profile" {
  description = "Name of existing IAM instance profile to use (if create_iam_role is false)"
  type        = string
  default     = null
}

variable "additional_iam_policies" {
  description = "Additional IAM policy ARNs to attach to the Keycloak instance role"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for policy_arn in var.additional_iam_policies : can(regex("^arn:aws:iam::[0-9]{12}:policy/", policy_arn))
    ])
    error_message = "All policy ARNs must be valid AWS IAM policy ARN format."
  }
}

# ===================================
# MONITORING CONFIGURATION
# ===================================

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for the instance"
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 20
  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 1000
    error_message = "Root volume size must be between 8 and 1000 GB."
  }
}

variable "root_volume_type" {
  description = "Type of the root EBS volume"
  type        = string
  default     = "gp3"
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.root_volume_type)
    error_message = "Root volume type must be one of: gp2, gp3, io1, io2."
  }
}

variable "root_volume_encrypted" {
  description = "Whether to encrypt the root EBS volume"
  type        = bool
  default     = true
}

# ===================================
# TAGGING
# ===================================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ===================================
# AWS CONFIGURATION
# ===================================

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be a valid format (e.g., us-east-2)."
  }
}

variable "aws_account_id" {
  description = "AWS account ID for resource ARN construction"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "AWS account ID must be a 12-digit number."
  }
}
