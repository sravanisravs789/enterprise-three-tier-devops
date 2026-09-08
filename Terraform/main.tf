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


# 4. Carve out a Public Subnet for our Compute Tier
resource "azurerm_subnet" "devops_subnet" {
  name                 = "devops-public-subnet"
  resource_group_name  = azurerm_resource_group.devops_rg.name
  virtual_network_name = azurerm_virtual_network.devops_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 5. Provision the Cloud Firewall (Network Security Group)
resource "azurerm_network_security_group" "devops_nsg" {
  name                = "devops-firewall-nsg"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name

  # Rule A: Open SSH access strictly for your management terminal
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*" # In production, pin this to your specific home IP!
    destination_address_prefix = "*"
  }

  # Rule B: Open port 8080 for your Web Frontend application container
  security_rule {
    name                       = "Allow-Frontend-8080"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 6. Bind the Firewall directly to the Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.devops_subnet.id
  network_security_group_id = azurerm_network_security_group.devops_nsg.id
}
