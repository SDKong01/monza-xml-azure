terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfmonzaxml8103"
    container_name       = "tfstate"
    key                  = "dev.tfstate"   # we’ll override per env if needed
  }
}
