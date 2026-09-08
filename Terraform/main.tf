# 1. Define the Microsoft Azure Provider version mapping
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 2. Establish the Enterprise Resource Group Grouping
resource "azurerm_resource_group" "devops_rg" {
  name     = "enterprise-devops-rg"
  location = "East US"
}

# 3. Provision the Isolated Virtual Network Space
resource "azurerm_virtual_network" "devops_vnet" {
  name                = "devops-secure-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name
}
