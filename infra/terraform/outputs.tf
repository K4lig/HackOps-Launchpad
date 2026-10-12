output "resource_group" { value = azurerm_resource_group.main.name }
output "acr_login_server" { value = azurerm_container_registry.main.login_server }
output "key_vault_name" { value = azurerm_key_vault.main.name }
output "aks_name" { value = azurerm_kubernetes_cluster.main.name }
output "api_identity_client_id" { value = azurerm_user_assigned_identity.api.client_id }
output "tenant_id" { value = data.azurerm_client_config.current.tenant_id }
output "gh_build_client_id" { value = azurerm_user_assigned_identity.gh_build.client_id }
output "gh_deploy_client_id" { value = azurerm_user_assigned_identity.gh_deploy.client_id }
output "ado_plan_client_id" { value = azurerm_user_assigned_identity.ado_plan.client_id }
output "appinsights_connection_string" {
  value     = azurerm_application_insights.main.connection_string
  sensitive = true
}
