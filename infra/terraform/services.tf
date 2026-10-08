resource "azurerm_container_registry" "main" {
  #checkov:skip=CKV_AZURE_164:Requiere Premium. Compensado con firma Cosign + Kyverno (fase extra)
  #checkov:skip=CKV_AZURE_237:Requiere Premium. Acceso solo por identidades con RBAC, admin desactivado
  #checkov:skip=CKV_AZURE_163:Compensado con escaneo Trivy obligatorio en CI antes del push
  #checkov:skip=CKV_AZURE_167:Requiere Premium. Limpieza manual en entorno dev efimero
  #checkov:skip=CKV_AZURE_233:Disponibilidad, no aplica a prototipo de una region
  #checkov:skip=CKV_AZURE_165:Disponibilidad, no aplica a prototipo de una region
  #checkov:skip=CKV_AZURE_166:Requiere Premium. Compensado con escaneo Trivy obligatorio en CI
  #checkov:skip=CKV_AZURE_139:Requiere Premium para private endpoint. Admin desactivado, solo RBAC
  name                = "acr${var.project}${var.env}${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = local.tags
}

resource "azurerm_key_vault" "main" {
  #checkov:skip=CKV_AZURE_42:Entorno dev efimero sin secretos de produccion; se activa en prod
  #checkov:skip=CKV_AZURE_110:Entorno dev efimero sin secretos de produccion; se activa en prod
  #checkov:skip=CKV2_AZURE_32:Pendiente Dia 5, private endpoint junto con AKS
  #checkov:skip=CKV_AZURE_189:Pendiente Dia 5, private endpoint junto con AKS
  name                       = "kv-${local.name}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  tags                       = local.tags

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.admin_ips
  }
}

resource "azurerm_role_assignment" "kv_admin_me" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${local.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}
