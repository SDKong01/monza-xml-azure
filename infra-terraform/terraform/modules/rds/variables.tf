variable "environment" {
  description = "The deployment environment (e.g., 'dev', 'staging', 'prod')."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "The name of the project."
  type        = string

  validation {
    condition     = length(var.project_name) > 0
    error_message = "Project name cannot be empty."
  }
}

variable "db_name" {
  description = "The name of the database to create."
  type        = string
  default     = "keycloak"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_name))
    error_message = "Database name must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "db_instance_identifier" {
  description = "The identifier for the RDS instance."
  type        = string
  default     = "keycloak-db"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.db_instance_identifier))
    error_message = "DB instance identifier must start with a letter and contain only alphanumeric characters and hyphens."
  }
}

variable "db_instance_class" {
  description = "The instance type of the RDS instance."
  type        = string
  default     = "db.t4g.micro"

  validation {
    condition     = can(regex("^db\\.", var.db_instance_class))
    error_message = "DB instance class must start with 'db.'."
  }
}

variable "db_allocated_storage" {
  description = "The allocated storage in gigabytes."
  type        = number
  default     = 20

  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 65536
    error_message = "Allocated storage must be between 20 and 65536 GB."
  }
}

variable "db_storage_type" {
  description = "The storage type for the RDS instance."
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.db_storage_type)
    error_message = "Storage type must be one of: gp2, gp3, io1, io2."
  }
}

variable "db_engine" {
  description = "The database engine to use."
  type        = string
  default     = "postgres"

  validation {
    condition     = var.db_engine == "postgres"
    error_message = "This module currently only supports PostgreSQL engine."
  }
}

variable "db_username" {
  description = "The master username for the database."
  type        = string

  validation {
    condition     = length(var.db_username) > 0 && length(var.db_username) <= 63
    error_message = "Database username must be between 1 and 63 characters."
  }
}

variable "db_password" {
  description = "The master password for the database."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

variable "vpc_id" {
  description = "The ID of the VPC where the DB instance will be created."
  type        = string

  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must start with 'vpc-'."
  }
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the DB subnet group."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnet IDs must be provided for Multi-AZ deployment capability."
  }
}

variable "keycloak_app_security_group_id" {
  description = "The ID of the security group for the Keycloak application, which needs access to the DB."
  type        = string

  validation {
    condition     = can(regex("^sg-", var.keycloak_app_security_group_id))
    error_message = "Security group ID must start with 'sg-'."
  }
}

variable "backup_retention_period" {
  description = "The number of days to retain backups."
  type        = number
  default     = 1

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 0 and 35 days."
  }
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ."
  type        = bool
  default     = false
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled."
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "The interval for collecting enhanced monitoring metrics. 0 disables enhanced monitoring."
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "common_tags" {
  description = "A map of tags to assign to all resources."
  type        = map(string)
  default     = {}
}
