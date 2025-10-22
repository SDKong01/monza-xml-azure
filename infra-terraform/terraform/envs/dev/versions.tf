# Development Environment Configuration
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "kainam-dev-tf-state"
    key     = "network/dev/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}

# Configure the AWS Provider
provider "aws" {
  region = local.aws_region

  default_tags {
    tags = local.common_tags
  }
}
