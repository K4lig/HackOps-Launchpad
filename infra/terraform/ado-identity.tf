data "azurerm_subscription" "current" {}

data "azurerm_storage_account" "tfstate" {
  name                = var.tfstate_storage_account
  resource_group_name = "rg-hackops-tfstate"
}

resource "azurerm_user_assigned_identity" "ado_plan" {
  name                = "id-ado-plan-${local.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "ado_plan" {
  name                      = "fic-ado-plan"
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = var.ado_issuer
  user_assigned_identity_id = azurerm_user_assigned_identity.ado_plan.id
  subject                   = var.ado_subject
}

resource "azurerm_role_assignment" "ado_plan_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.ado_plan.principal_id
}

resource "azurerm_role_assignment" "ado_plan_state" {
  scope                = data.azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.ado_plan.principal_id
}
