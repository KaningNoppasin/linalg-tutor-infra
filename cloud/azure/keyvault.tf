# Holds exactly ONE secret: the Tailscale auth key for the edge VM.
# The secret value is set with the az CLI (see README), so it never appears in tofu state.
resource "azurerm_key_vault" "tutor" {
  #checkov:skip=CKV_AZURE_42:Lab - purge protection off so destroy/recreate works; enable for production
  #checkov:skip=CKV_AZURE_110:Lab - purge protection off so destroy/recreate works; enable for production
  #checkov:skip=CKV_AZURE_189:Public endpoint kept (private endpoint ~US$7/mo); restricted by network_acls to edge VM + admin IPs
  name                       = "kv-${var.prefix}-${local.suffix}" # globally unique, 3–24 chars
  location                   = azurerm_resource_group.tutor.location
  resource_group_name        = azurerm_resource_group.tutor.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true # Azure RBAC instead of access policies
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # lab: allows destroy + recreate with the same name. Turn on for real prod.
  tags                       = local.tags

  # Key Vault firewall: only the edge VM (its public IP) and your admin IP(s) can reach it.
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = concat([azurerm_public_ip.edge.ip_address], var.admin_ip_cidrs)
  }
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
