output "resource_group" { value = azurerm_resource_group.main.name }
output "acr_login_server" { value = azurerm_container_registry.main.login_server }
output "key_vault_name" { value = azurerm_key_vault.main.name }
output "aks_name" { value = azurerm_kubernetes_cluster.main.name }
