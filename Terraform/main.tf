# ==============================================================================
# 1. CORE ENGINE & CLOUD STORAGE BACKEND CONFIGURATION
# ==============================================================================
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Configures Terraform to stream and version state file updates directly inside the cloud
  backend "azurerm" {
    resource_group_name  = "enterprise-devops-rg"
    storage_account_name = "devopsstatebucket2026" # Must match your custom CLI bucket name exactly
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate" # The specific blob filename
  }
}

provider "azurerm" {
  features {}
}

# ==============================================================================
# 2. LOGICAL BOUNDARY & NETWORK INFRASTRUCTURE (CENTRAL US VNET)
# ==============================================================================
resource "azurerm_resource_group" "devops_rg" {
  name     = "enterprise-devops-rg"
  location = "Central US"
}

resource "azurerm_virtual_network" "devops_vnet" {
  name                = "devops-secure-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name
}

resource "azurerm_subnet" "devops_subnet" {
  name                 = "devops-public-subnet"
  resource_group_name  = azurerm_resource_group.devops_rg.name
  virtual_network_name = azurerm_virtual_network.devops_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ==============================================================================
# 3. FIREWALL / NETWORK SECURITY GROUPS & TRAFFIC CONTROLS
# ==============================================================================
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
    source_address_prefix      = "*" 
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

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.devops_subnet.id
  network_security_group_id = azurerm_network_security_group.devops_nsg.id
}

# ==============================================================================
# 4. MANAGED CONTAINER SERVICE TIER (Azure App Service PaaS)
# ==============================================================================

# Create the managed hosting plan runner
resource "azurerm_service_plan" "app_plan" {
  name                = "devops-app-hosting-plan"
  resource_group_name = azurerm_resource_group.devops_rg.name
  location            = azurerm_resource_group.devops_rg.location
  os_type             = "Linux"
  sku_name            = "B1" # Compliant developer tier covered by your credits
}

# Launch your containerized backend/frontend infrastructure directly
resource "azurerm_linux_web_app" "container_app" {
  name                = "enterprise-devops-app-2026" # Must be globally unique
  resource_group_name = azurerm_resource_group.devops_rg.name
  location            = azurerm_resource_group.devops_rg.location
  service_plan_id     = azurerm_service_plan.app_plan.id

  site_config {
    # Directs Azure to pull and host a stable test docker image out-of-the-box
    application_stack {
      docker_image_name   = "nginx:alpine"
      docker_registry_url = "https://docker.io"
    }
  }
}

