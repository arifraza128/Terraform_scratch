provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "acr-resource-group"
  location = "East US"
}

resource "azurerm_container_registry" "acr" {
  name                = "arifacr12345"   # must be globally unique
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"          # Basic / Standard / Premium
  admin_enabled       = true
}
