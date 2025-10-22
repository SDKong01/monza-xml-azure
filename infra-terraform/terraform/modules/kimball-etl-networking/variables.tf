
variable "vpc_id" {
  description = "ID of the existing VPC where ETL resources will be created"
  type        = string
  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must be a valid VPC identifier starting with 'vpc-'."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
  default     = "kainam"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}



variable "availability_zone" {
  description = "Availability zone for ETL subnets"
  type        = string
  default     = "us-east-2a"
  validation {
    condition     = can(regex("^us-east-2[a-z]$", var.availability_zone))
    error_message = "Availability zone must be in us-east-2 region (e.g., us-east-2a, us-east-2b)."
  }
}

variable "etl_public_subnet_cidr" {
  description = "CIDR block for ETL public subnet"
  type        = string
  default     = "10.0.3.0/24"
  validation {
    condition     = can(cidrhost(var.etl_public_subnet_cidr, 0))
    error_message = "ETL public subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "etl_private_subnet_cidr" {
  description = "CIDR block for ETL private subnet"
  type        = string
  default     = "10.0.103.0/24"
  validation {
    condition     = can(cidrhost(var.etl_private_subnet_cidr, 0))
    error_message = "ETL private subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC for internal security group rules"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_route_table_id" {
  description = "ID of the existing public route table"
  type        = string
  validation {
    condition     = can(regex("^rtb-", var.public_route_table_id))
    error_message = "Public route table ID must be a valid route table identifier starting with 'rtb-'."
  }
}

variable "private_route_table_id" {
  description = "ID of the existing private route table"
  type        = string
  validation {
    condition     = can(regex("^rtb-", var.private_route_table_id))
    error_message = "Private route table ID must be a valid route table identifier starting with 'rtb-'."
  }
}

variable "trusted_ip_ranges" {
  description = "List of trusted IP ranges for SSH and database access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Default allows all - restrict in production
  validation {
    condition = alltrue([
      for cidr in var.trusted_ip_ranges : can(cidrhost(cidr, 0))
    ])
    error_message = "All trusted IP ranges must be valid IPv4 CIDR blocks."
  }
}

variable "allow_all_external_access" {
  description = "Whether to allow external access from all IPs (0.0.0.0/0) - use false for production"
  type        = bool
  default     = true # Development mode - set to false for production
}

variable "etl_external_ports" {
  description = "Map of external ETL service ports"
  type = object({
    ssh            = number
    http           = number
    https          = number
    airflow        = number
    minio_api      = number
    minio_console  = number
    hive_metastore = number
    hive_server2   = number
  })
  default = {
    ssh            = 22
    http           = 80
    https          = 443
    airflow        = 8088
    minio_api      = 9000
    minio_console  = 9001
    hive_metastore = 9083
    hive_server2   = 10000
  }
}

variable "etl_internal_ports" {
  description = "Map of internal ETL service ports"
  type = object({
    redis                = number
    spark_master         = number
    spark_master_ui      = number
    spark_worker_ui      = number
    spark_executor_start = number
    spark_executor_end   = number
  })
  default = {
    redis                = 6379
    spark_master         = 7077
    spark_master_ui      = 8080
    spark_worker_ui      = 8081
    spark_executor_start = 40000
    spark_executor_end   = 50000
  }
}

variable "etl_database_ports" {
  description = "Map of ETL database service ports"
  type = object({
    mysql = number
  })
  default = {
    mysql = 3306
  }
}

variable "common_tags" {
  description = "Common tags to apply to all ETL networking resources"
  type        = map(string)
  default = {
    Project     = "kainam"
    Component   = "kimball-etl"
    Terraform   = "true"
    Environment = "dev"
  }
}

variable "additional_tags" {
  description = "Additional tags to apply to ETL networking resources"
  type        = map(string)
  default     = {}
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC Flow Logs for ETL subnets"
  type        = bool
  default     = false
}

variable "enable_detailed_monitoring" {
  description = "Whether to enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}
