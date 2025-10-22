#!/bin/bash

# Deploy application to Azure App Service using Terraform
set -e

ENVIRONMENT=${1:-dev}
APP_NAME="monza-xml-azure"
TERRAFORM_DIR="../terraform"

echo "🚀 Deploying application to Azure App Service"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it first."
    exit 1
fi

# Get App Service name from Terraform output
echo "📋 Getting App Service details from Terraform..."
cd $TERRAFORM_DIR
APP_SERVICE_NAME=$(terraform output -raw app_service_name)
RESOURCE_GROUP_NAME=$(terraform output -raw resource_group_name)

echo "🏗️  App Service: $APP_SERVICE_NAME"
echo "📦 Resource Group: $RESOURCE_GROUP_NAME"

# Create deployment package
echo "📦 Creating deployment package..."
cd ..
zip -r app.zip . -x "*.git*" "azure-deployment/*" "*.pyc" "__pycache__/*" "*.zip"

# Deploy to Azure App Service
echo "🌐 Deploying to Azure App Service..."
az webapp deployment source config-zip \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $APP_SERVICE_NAME \
    --src app.zip

# Clean up
rm app.zip

# Get the App Service URL
APP_URL=$(terraform -chdir=$TERRAFORM_DIR output -raw app_service_url)

echo "✅ Application deployed successfully!"
echo "🌐 URL: $APP_URL"
