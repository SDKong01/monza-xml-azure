# =============================================================================
# Authentication ALB Module Variables
# =============================================================================
# Description: Variables for the Authentication Application Load Balancer module
# This module creates an internet-facing ALB and target group for Keycloak

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
  description = "VPC ID where the ALB will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC identifier."
  }
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB deployment"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least 2 public subnets are required for ALB high availability."
  }
}

variable "security_group_id" {
  description = "Security group ID for the ALB"
  type        = string

  validation {
    condition     = can(regex("^sg-[a-z0-9]+$", var.security_group_id))
    error_message = "Security group ID must be a valid AWS security group identifier."
  }
}



variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}
