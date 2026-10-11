output "resource_group" { value = azurerm_resource_group.main.name }
output "acr_login_server" { value = azurerm_container_registry.main.login_server }
output "key_vault_name" { value = azurerm_key_vault.main.name }
output "aks_name" { value = azurerm_kubernetes_cluster.main.name }
output "api_identity_client_id" { value = azurerm_user_assigned_identity.api.client_id }
output "tenant_id" { value = data.azurerm_client_config.current.tenant_id }
