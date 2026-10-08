resource "azurerm_linux_virtual_machine" "edge" {
  name                            = "vm-${var.prefix}-edge"
  computer_name                   = "edge"
  location                        = azurerm_resource_group.tutor.location
  resource_group_name             = azurerm_resource_group.tutor.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.edge.id]
  encryption_at_host_enabled      = true # needs the EncryptionAtHost feature registered (step 4)

  admin_ssh_key { # required by the API; port 22 stays closed in the NSG
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    name                 = "osdisk-${var.prefix}-edge"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-12"
    sku       = "12-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned" # managed identity → reads the Tailscale key, no credentials on disk
  }

  boot_diagnostics {} # managed storage; enables Serial Console as break-glass access

  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml.tftpl", {
    key_vault_name = azurerm_key_vault.tutor.name
    ts_secret_name = var.tailscale_secret_name
    ts_hostname    = "edge"
  }))

  tags = local.tags

  lifecycle {
    # cloud-init only runs on first boot; don't rebuild the VM when the template is edited.
    ignore_changes = [custom_data]
  }
}
