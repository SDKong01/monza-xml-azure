#!/bin/bash

# Terraform Azure deployment script
set -e

ENVIRONMENT=${1:-dev}
TERRAFORM_DIR="../terraform"

echo "🚀 Deploying to Azure using Terraform ($ENVIRONMENT)"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it first."
    echo "📖 Install instructions: https://developer.hashicorp.com/terraform/downloads"
    exit 1
fi

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    echo "📖 Install instructions: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Login to Azure
echo "🔐 Logging in to Azure..."
az login

# Initialize Terraform
echo "🔧 Initializing Terraform..."
cd $TERRAFORM_DIR
terraform init

# Plan deployment
echo "📋 Planning Terraform deployment..."
terraform plan -var-file="environments/$ENVIRONMENT/terraform.tfvars"

# Apply deployment
echo "🏗️  Deploying infrastructure with Terraform..."
terraform apply -var-file="environments/$ENVIRONMENT/terraform.tfvars" -auto-approve

# Get outputs
echo "📊 Deployment outputs:"
terraform output

echo "✅ Terraform deployment completed!"
echo "🌐 Check the outputs above for your App Service URL"
