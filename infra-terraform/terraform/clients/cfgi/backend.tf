# =============================================================================
# TERRAFORM BACKEND CONFIGURATION
# =============================================================================
# 
# S3 Backend for CFGI Client Terraform State Management
# 
# Prerequisites (Manual Setup Required):
#   1. Create S3 bucket: cfgi-tf-state in CFGI AWS account
#   2. Enable versioning on the bucket
#   3. Enable server-side encryption (AES256 or KMS)
#   4. Create DynamoDB table: cfgi-tf-state-lock
#      - Partition key: LockID (String)
#   5. Configure AWS CLI profile: cfgi-sso
#
# Usage:
#   terraform init -backend-config="profile=cfgi-sso"
#
# =============================================================================

terraform {
  backend "s3" {
    # S3 Bucket Configuration
    bucket = "cfgi-tf-state"
    key    = "infrastructure/prod/terraform.tfstate"
    region = "us-east-2"

    # State Encryption
    encrypt = true

    # State Locking via DynamoDB (Disabled - not using DynamoDB table)
    # dynamodb_table = "cfgi-tf-state-lock"

    # AWS Profile for Cross-Account Access
    profile = "cfgi-sso"

    # Additional Security and Performance Settings
    # skip_credentials_validation = false
    # skip_metadata_api_check     = false
    # skip_region_validation      = false
  }
}
