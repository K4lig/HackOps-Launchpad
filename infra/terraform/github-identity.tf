resource "azurerm_user_assigned_identity" "gh_build" {
  name                = "id-gh-build-${local.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "gh_build" {
  name                      = "fic-gh-build-main"
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  user_assigned_identity_id = azurerm_user_assigned_identity.gh_build.id
  subject                   = "repo:${var.github_repo}:ref:refs/heads/main"
}

resource "azurerm_role_assignment" "gh_build_acr_push" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.gh_build.principal_id
}

resource "azurerm_user_assigned_identity" "gh_deploy" {
  name                = "id-gh-deploy-${local.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "gh_deploy" {
  name                      = "fic-gh-deploy-production"
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  user_assigned_identity_id = azurerm_user_assigned_identity.gh_deploy.id
  subject                   = "repo:${var.github_repo}:environment:production"
}

resource "azurerm_role_definition" "aks_command_invoke" {
  name  = "AKS Command Invoke (${local.name})"
  scope = azurerm_kubernetes_cluster.main.id

  permissions {
    actions = [
      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.ContainerService/managedClusters/runcommand/action",
      "Microsoft.ContainerService/managedclusters/commandResults/read",
    ]
  }

  assignable_scopes = [azurerm_kubernetes_cluster.main.id]
}

resource "azurerm_role_assignment" "gh_deploy_command_invoke" {
  scope              = azurerm_kubernetes_cluster.main.id
  role_definition_id = azurerm_role_definition.aks_command_invoke.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.gh_deploy.principal_id
}

resource "azurerm_role_assignment" "gh_deploy_namespace_admin" {
  scope                = "${azurerm_kubernetes_cluster.main.id}/namespaces/cve-copilot"
  role_definition_name = "Azure Kubernetes Service RBAC Admin"
  principal_id         = azurerm_user_assigned_identity.gh_deploy.principal_id
}
