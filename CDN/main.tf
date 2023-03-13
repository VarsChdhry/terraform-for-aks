resource "azurerm_resource_group" "aks-rg-cdn" {
  name = "aks-rg-cdn"
  location = "canadacentral"
}


resource "azurerm_storage_account" "aksstorage" {
  name                     = "varshastorageforaks"
  resource_group_name      = azurerm_resource_group.aks-rg-cdn.name
  location                 = azurerm_resource_group.aks-rg-cdn.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "images" {
  name                  = "images"
  storage_account_name  = azurerm_storage_account.aksstorage.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "exa" {
  name                   = "some-images"
  storage_account_name   = azurerm_storage_account.aksstorage.name
  storage_container_name = azurerm_storage_container.images.name
  type                   = "Block"
}

resource "azurerm_cdn_profile" "cdnforaks" {
  name                = "cdnforaksprofile"
  location            = azurerm_resource_group.aks-rg-cdn.location
  resource_group_name = azurerm_resource_group.aks-rg-cdn.name
  sku                 = "Standard_Verizon"

}

resource "azurerm_cdn_endpoint" "cdnendpoint" {
  name                = "vntest"
  profile_name        = azurerm_cdn_profile.cdnforaks.name
  location            = azurerm_resource_group.aks-rg-cdn.location
  resource_group_name = azurerm_resource_group.aks-rg-cdn.name

  origin {
    name = "vntest"
    host_name = "${azurerm_storage_account.aksstorage.name}.blob.core.windows.net"
  }
}

data "azurerm_dns_zone" "varsha" {
  name                = "varsha.one"
  resource_group_name = "aks-tf"
}

resource "azurerm_dns_cname_record" "cnamerecord" {
  name                = "cdn"
  zone_name           = data.azurerm_dns_zone.varsha.name
  resource_group_name = data.azurerm_dns_zone.varsha.resource_group_name
  ttl                 = 3600
  target_resource_id  = azurerm_cdn_endpoint.cdnendpoint.id
}

resource "azurerm_cdn_endpoint_custom_domain" "customendpoint" {
  name            = "vntest"
  cdn_endpoint_id = azurerm_cdn_endpoint.cdnendpoint.id
  host_name       = "${azurerm_dns_cname_record.cnamerecord.name}.${data.azurerm_dns_zone.varsha.name}"
}
