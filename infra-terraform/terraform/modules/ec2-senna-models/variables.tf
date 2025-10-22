# EC2 Instance Module Variables
# Provides flexible configuration for EC2 instances with security groups, IAM roles, and key pairs

# Project Configuration
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

# Instance Configuration
variable "instance_name" {
  description = "Name of the EC2 instance (will be prefixed with project-environment)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
  validation {
    condition     = can(regex("^[a-z][0-9][a-z]?\\.[a-z0-9]+$", var.instance_type))
    error_message = "Instance type must be a valid EC2 instance type format (e.g., t3.medium, c6i.xlarge)."
  }
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (if not provided, latest Amazon Linux 2023 will be used)"
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data script to run on instance launch"
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with the instance"
  type        = bool
  default     = true
}

# Network Configuration
variable "vpc_id" {
  description = "VPC ID where the instance will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be deployed"
  type        = string
}

# Security Configuration
variable "create_security_group" {
  description = "Whether to create a new security group for the instance"
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Name of the security group (only used if create_security_group is true)"
  type        = string
  default     = null
}

variable "existing_security_group_ids" {
  description = "List of existing security group IDs to attach (used if create_security_group is false)"
  type        = list(string)
  default     = []
}

variable "ingress_rules" {
  description = "List of ingress rules for the security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "egress_rules" {
  description = "List of egress rules for the security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [{
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }]
}

# IAM Configuration
variable "create_iam_role" {
  description = "Whether to create a new IAM role for the instance"
  type        = bool
  default     = true
}

variable "iam_role_name" {
  description = "Name of the IAM role (only used if create_iam_role is true)"
  type        = string
  default     = null
}

variable "existing_iam_instance_profile" {
  description = "Name of existing IAM instance profile (used if create_iam_role is false)"
  type        = string
  default     = null
}

variable "iam_managed_policy_arns" {
  description = "List of AWS managed policy ARNs to attach to the IAM role"
  type        = list(string)
  default     = []
}

variable "iam_custom_policies" {
  description = "List of custom IAM policies to create and attach"
  type = list(object({
    name        = string
    description = string
    policy_json = string
  }))
  default = []
}

# Key Pair Configuration
variable "create_key_pair" {
  description = "Whether to create a new key pair for the instance"
  type        = bool
  default     = true
}

variable "key_pair_name" {
  description = "Name of the key pair (only used if create_key_pair is true)"
  type        = string
  default     = null
}

variable "existing_key_pair_name" {
  description = "Name of existing key pair (used if create_key_pair is false)"
  type        = string
  default     = null
}

variable "key_pair_public_key" {
  description = "Public key material for the key pair (only used if create_key_pair is true and public key is provided)"
  type        = string
  default     = null
}

# Storage Configuration
variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 16384
    error_message = "Root volume size must be between 8 and 16384 GB."
  }
}

variable "root_volume_type" {
  description = "Type of the root volume (gp3, gp2, io1, io2)"
  type        = string
  default     = "gp3"
  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2"], var.root_volume_type)
    error_message = "Root volume type must be one of: gp3, gp2, io1, io2."
  }
}

variable "root_volume_encrypted" {
  description = "Whether to encrypt the root volume"
  type        = bool
  default     = true
}

variable "additional_volumes" {
  description = "List of additional EBS volumes to attach"
  type = list(object({
    device_name = string
    size        = number
    type        = string
    encrypted   = bool
  }))
  default = []
}

# Monitoring Configuration
variable "enable_detailed_monitoring" {
  description = "Whether to enable detailed monitoring for the instance"
  type        = bool
  default     = false
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
