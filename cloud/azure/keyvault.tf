# Holds exactly ONE secret: the Tailscale auth key for the edge VM.
# The secret value is set with the az CLI (see README), so it never appears in tofu state.
resource "azurerm_key_vault" "tutor" {
  name                       = "kv-${var.prefix}-${local.suffix}" # globally unique, 3–24 chars
  location                   = azurerm_resource_group.tutor.location
  resource_group_name        = azurerm_resource_group.tutor.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true  # Azure RBAC instead of access policies
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # lab: allows destroy + recreate with the same name. Turn on for real prod.
  tags                       = local.tags
}

# You (the identity running tofu / az CLI) may write secrets into this vault.
resource "azurerm_role_assignment" "me_kv_secrets_officer" {
  scope                = azurerm_key_vault.tutor.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# The edge VM may only READ secrets, and this vault contains only the one Tailscale key.
resource "azurerm_role_assignment" "edge_kv_secrets_user" {
  scope                = azurerm_key_vault.tutor.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_virtual_machine.edge.identity[0].principal_id
}
