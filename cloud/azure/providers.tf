provider "azurerm" {
  subscription_id = var.subscription_id # required by azurerm v4

  features {
    key_vault {
      # Lab-friendly: `tofu destroy` then `tofu apply` can reuse the same vault name.
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    recovery_service {
      # Lab-friendly: destroying the VM also removes its backup data, so the vault can be deleted.
      vm_backup_stop_protection_and_retain_data_on_destroy = false
      purge_protected_items_from_vault_on_destroy          = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

data "azurerm_client_config" "current" {}
