resource "azurerm_consumption_budget_resource_group" "main" {
  name              = "budget-${local.name}"
  resource_group_id = azurerm_resource_group.main.id
  amount            = 20
  time_grain        = "Monthly"

  time_period {
    start_date = "2026-10-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    contact_emails = [var.budget_email]
  }

  notification {
    enabled        = true
    threshold      = 90
    operator       = "GreaterThan"
    contact_emails = [var.budget_email]
  }
}
