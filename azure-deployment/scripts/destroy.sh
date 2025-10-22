#!/bin/bash

# Destroy Azure infrastructure using Terraform
set -e

ENVIRONMENT=${1:-dev}
TERRAFORM_DIR="../terraform"

echo "🗑️  Destroying Azure infrastructure ($ENVIRONMENT)"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it first."
    exit 1
fi

# Confirm destruction
echo "⚠️  WARNING: This will destroy all resources in the $ENVIRONMENT environment!"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Destruction cancelled."
    exit 1
fi

# Initialize Terraform
echo "🔧 Initializing Terraform..."
cd $TERRAFORM_DIR
terraform init

# Destroy infrastructure
echo "🗑️  Destroying infrastructure with Terraform..."
terraform destroy -var-file="environments/$ENVIRONMENT/terraform.tfvars" -auto-approve

echo "✅ Infrastructure destroyed successfully!"
