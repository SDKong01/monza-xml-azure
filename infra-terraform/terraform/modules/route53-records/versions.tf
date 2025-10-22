# =============================================================================
# Route 53 Records Module Provider Requirements
# =============================================================================
# Description: Terraform and provider version constraints for the Route 53 Records module

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
