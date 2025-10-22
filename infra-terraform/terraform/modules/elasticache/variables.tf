# ===================================
# Core Configuration Variables
# ===================================

variable "environment" {
  description = "Environment name (e.g., dev, uat, prod)"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.environment))
    error_message = "Environment must start with a letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number."
  }
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name))
    error_message = "Project name must start with a letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number."
  }
}

variable "service_name" {
  description = "Service name for ElastiCache cluster naming (e.g., senna, kimball)"
  type        = string
  default     = "senna"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.service_name))
    error_message = "Service name must start with a letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number."
  }
}

# ===================================
# ElastiCache Configuration
# ===================================

variable "cluster_id" {
  description = "ElastiCache cluster identifier"
  type        = string
  default     = null
}

variable "description" {
  description = "Description for the ElastiCache cluster"
  type        = string
  default     = "ElastiCache Redis cluster for caching"
}

variable "engine" {
  description = "Cache engine (redis, memcached, valkey)"
  type        = string
  default     = "redis"
  validation {
    condition     = contains(["redis", "memcached", "valkey"], var.engine)
    error_message = "Engine must be one of: redis, memcached, valkey."
  }
}

variable "engine_version" {
  description = "Engine version for the cache cluster"
  type        = string
  default     = "7.0"
}

variable "node_type" {
  description = "Instance class for the cache nodes"
  type        = string
  default     = "cache.t4g.small"
}

variable "num_cache_nodes" {
  description = "Number of cache nodes in the cluster (Redis: must be 1, Memcached: 1-40)"
  type        = number
  default     = 1
  validation {
    condition     = var.num_cache_nodes >= 1 && var.num_cache_nodes <= 40
    error_message = "Number of cache nodes must be between 1 and 40."
  }
}

variable "port" {
  description = "Port number for cache connections (Redis: 6379, Memcached: 11211)"
  type        = number
  default     = 6379
}

# ===================================
# Cluster Mode Configuration
# ===================================

variable "cluster_mode_enabled" {
  description = "Whether to enable Redis cluster mode"
  type        = bool
  default     = false
}

variable "num_node_groups" {
  description = "Number of node groups (shards) for Redis cluster mode"
  type        = number
  default     = null
}

variable "replicas_per_node_group" {
  description = "Number of replica nodes per node group in cluster mode"
  type        = number
  default     = null
}

# ===================================
# High Availability Configuration
# ===================================

variable "automatic_failover_enabled" {
  description = "Enable automatic failover for Redis replication groups"
  type        = bool
  default     = false
}

variable "multi_az_enabled" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

# ===================================
# Network Configuration
# ===================================

variable "vpc_id" {
  description = "VPC ID where the ElastiCache cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ElastiCache subnet group"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least one subnet ID must be provided."
  }
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with the cache cluster"
  type        = list(string)
  default     = []
}

# ===================================
# Security Configuration
# ===================================

variable "at_rest_encryption_enabled" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "Enable encryption in transit"
  type        = bool
  default     = false
}

variable "auth_token" {
  description = "Auth token for Redis (required if transit encryption is enabled)"
  type        = string
  default     = null
  sensitive   = true
}

# ===================================
# Maintenance Configuration
# ===================================

variable "maintenance_window" {
  description = "Maintenance window for updates (e.g., sun:05:00-sun:09:00)"
  type        = string
  default     = "sun:05:00-sun:09:00"
}

variable "apply_immediately" {
  description = "Apply changes immediately or during next maintenance window"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

# ===================================
# Backup Configuration
# ===================================

variable "snapshot_retention_limit" {
  description = "Number of days to retain snapshots (Redis only, 0-35)"
  type        = number
  default     = 5
  validation {
    condition     = var.snapshot_retention_limit >= 0 && var.snapshot_retention_limit <= 35
    error_message = "Snapshot retention limit must be between 0 and 35 days."
  }
}

variable "snapshot_window" {
  description = "Daily snapshot window in UTC (e.g., 05:00-09:00)"
  type        = string
  default     = "03:00-05:00"
}

variable "final_snapshot_identifier" {
  description = "Name of final snapshot when cluster is deleted (Redis only)"
  type        = string
  default     = null
}

# ===================================
# Parameter Group Configuration
# ===================================

variable "create_parameter_group" {
  description = "Whether to create a custom parameter group"
  type        = bool
  default     = true
}

variable "parameter_group_family" {
  description = "Parameter group family (e.g., redis7, memcached1.6)"
  type        = string
  default     = "redis7"
}

variable "parameters" {
  description = "List of parameters to apply to the parameter group"
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
# Tagging Configuration
# ===================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "additional_tags" {
  description = "Additional tags specific to ElastiCache resources"
  type        = map(string)
  default     = {}
}
