#############################################
# Monza XML — ACR + Azure Container Apps
#############################################

terraform {
  required_version = ">= 1.6, < 2.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.110" }
    random  = { source = "hashicorp/random",  version = "~> 3.6" }
  }
}

provider "azurerm" { features {} }

# -------------------------
# Variables
# -------------------------
variable "environment" {
  description = "Environment name (dev, stg, prod)"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Application name (used for naming resources)"
  type        = string
  default     = "monza-xml"
}

variable "location" {
  description = "Azure region short name"
  type        = string
  default     = "eastus"
}

# image tag provided by CI on each deploy; can be 'local' for manual runs
variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "local"
}

variable "tags" {
  type        = map(string)
  default     = {}
}

# -------------------------
# Locals (consistent names)
# -------------------------
locals {
  env              = lower(var.environment)
  app              = lower(var.app_name)
  name_root        = replace(local.app, "-", "")
  rg_name          = "rg-${local.app}-${local.env}"
  acr_name         = "acr${local.name_root}${local.env}"         # e.g., acrmonzaxmldev
  cae_name         = "cae-${local.app}-${local.env}"
  ca_name          = "api-${local.app}-${local.env}"
  law_name         = "law-${local.app}-${local.env}"
  tags             = merge(var.tags, { app = var.app_name, env = var.environment })
}

# -------------------------
# Resource Group
# -------------------------
resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
  tags     = local.tags
}

# -------------------------
# Log Analytics (for CAE logs/metrics)
# -------------------------
resource "azurerm_log_analytics_workspace" "law" {
  name                = local.law_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# -------------------------
# Azure Container Registry (ACR)
# -------------------------
resource "azurerm_container_registry" "acr" {
  name                = local.acr_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
  admin_enabled       = false
  tags                = local.tags
}

# -------------------------
# Container Apps Environment (CAE)
# -------------------------
resource "azurerm_container_app_environment" "cae" {
  name                = local.cae_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Most azurerm versions still expect a Log Analytics workspace
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  # Optional network, Dapr, etc., can be added here later
  tags = local.tags
}

# -------------------------
# Container App (uses image from ACR)
# -------------------------
resource "azurerm_container_app" "app" {
  name                         = local.ca_name
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.cae.id
  revision_mode                = "Single"

  # Use system-assigned identity and grant it AcrPull (role assignment below)
  identity { type = "SystemAssigned" }

  # Pull from ACR using managed identity (no secrets)
  registry {
    server = azurerm_container_registry.acr.login_server
    # In recent providers, this sub-block tells CA to use the resource's identity for ACR
    identity {
      use_system_assigned_identity = true
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8080     # make sure your container listens here
    transport        = "auto"
  }

  template {
    container {
      name   = "api"
      image  = "${azurerm_container_registry.acr.login_server}/${local.app}:${var.image_tag}"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }
    }
    min_replicas = 0
    max_replicas = 3
  }

  tags = local.tags
}

# -------------------------
# Grant AcrPull to the app's managed identity
# -------------------------
data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_app.app.identity[0].principal_id

  depends_on = [azurerm_container_app.app]
}

# -------------------------
# Outputs
# -------------------------
output "resource_group"   { value = azurerm_resource_group.rg.name }
output "acr_name"         { value = azurerm_container_registry.acr.name }
output "acr_login_server" { value = azurerm_container_registry.acr.login_server }
output "container_app_fqdn" {
  description = "Public URL of the app"
  value       = azurerm_container_app.app.latest_revision_fqdn
}
