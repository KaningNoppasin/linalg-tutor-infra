locals {
  # Deterministic 6-char suffix for globally-unique names (Key Vault), no extra provider needed.
  suffix = substr(sha1(var.subscription_id), 0, 6)
  tags   = var.tags
}

resource "azurerm_resource_group" "tutor" {
  name     = "rg-${var.prefix}-tutor"
  location = var.location
  tags     = local.tags
}
