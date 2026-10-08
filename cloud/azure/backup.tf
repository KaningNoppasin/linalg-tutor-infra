resource "azurerm_recovery_services_vault" "tutor" {
  count               = var.enable_backup ? 1 : 0
  name                = "rsv-${var.prefix}"
  location            = azurerm_resource_group.tutor.location
  resource_group_name = azurerm_resource_group.tutor.name
  sku                 = "Standard"
  storage_mode_type   = "LocallyRedundant"
  # Soft delete is always on (Azure secure-by-default): deleted backups are kept 14 days,
  # and the vault can't be deleted until they expire.
  tags = local.tags
}

resource "azurerm_backup_policy_vm" "daily" {
  count               = var.enable_backup ? 1 : 0
  name                = "daily-keep7"
  resource_group_name = azurerm_resource_group.tutor.name
  recovery_vault_name = azurerm_recovery_services_vault.tutor[0].name
  timezone            = "SE Asia Standard Time" # UTC+7

  backup {
    frequency = "Daily"
    time      = "03:00"
  }

  retention_daily {
    count = 7
  }
}

resource "azurerm_backup_protected_vm" "edge" {
  count               = var.enable_backup ? 1 : 0
  resource_group_name = azurerm_resource_group.tutor.name
  recovery_vault_name = azurerm_recovery_services_vault.tutor[0].name
  source_vm_id        = azurerm_linux_virtual_machine.edge.id
  backup_policy_id    = azurerm_backup_policy_vm.daily[0].id
}
