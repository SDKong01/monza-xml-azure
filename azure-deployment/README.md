# Azure Deployment

Terraform-based Azure deployment for Monza XML Azure application.

## Quick Deploy

1. **Deploy Infrastructure**:
   ```bash
   ./scripts/deploy.sh dev
   ```

2. **Deploy Application**:
   ```bash
   ./scripts/deploy-app.sh dev
   ```

## Prerequisites

- **Terraform** (>= 1.0) - [Install Terraform](https://developer.hashicorp.com/terraform/downloads)
- **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Azure Subscription** with appropriate permissions

## Files

- `terraform/main.tf` - Main Terraform configuration
- `terraform/environments/dev/terraform.tfvars` - Development environment variables
- `terraform/environments/prod/terraform.tfvars` - Production environment variables
- `scripts/deploy.sh` - Deploy infrastructure with Terraform
- `scripts/deploy-app.sh` - Deploy application to App Service

## Manual Deployment

```bash
# Initialize Terraform
cd terraform
terraform init

# Plan deployment
terraform plan -var-file="environments/dev/terraform.tfvars"

# Apply deployment
terraform apply -var-file="environments/dev/terraform.tfvars"
```
