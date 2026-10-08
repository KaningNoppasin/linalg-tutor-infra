# Optional: Azure for Students (sponsorship offer) may not support Cost Management budgets.
# If apply fails here, set enable_budget = false and watch credit at https://www.microsoftazuresponsorships.com
resource "azurerm_consumption_budget_resource_group" "tutor" {
  count             = var.enable_budget && var.budget_contact_email != "" ? 1 : 0
  name              = "budget-${var.prefix}-monthly"
  resource_group_id = azurerm_resource_group.tutor.id
  amount            = var.budget_amount
  time_grain        = "Monthly"

  time_period {
    start_date = var.budget_start_date
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = [var.budget_contact_email]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    contact_emails = [var.budget_contact_email]
  }
}
