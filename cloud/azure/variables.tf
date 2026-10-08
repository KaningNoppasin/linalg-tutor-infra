variable "subscription_id" {
  description = "Azure subscription ID (az account show --query id -o tsv)."
  type        = string
}

variable "location" {
  description = "Azure region. Must be allowed by the Azure for Students 'Allowed locations' policy."
  type        = string
  default     = "southeastasia"
}

variable "prefix" {
  description = "Short name used in resource names."
  type        = string
  default     = "linalg"
}

variable "vnet_cidr" {
  description = "Azure VNet range. Must not overlap the home LAN 10.10.10.0/24."
  type        = string
  default     = "10.100.0.0/16"
}

variable "edge_subnet_cidr" {
  type    = string
  default = "10.100.1.0/24"
}

variable "vm_size" {
  description = "Edge VM size. Standard_B2s = 2 vCPU / 4 GB (x64)."
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Public key Azure requires at create time. Port 22 is still CLOSED in the NSG; admin access is Tailscale SSH."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "tailscale_secret_name" {
  description = "Key Vault secret holding the Tailscale auth key (set with az CLI, never in tofu state)."
  type        = string
  default     = "tailscale-authkey"
}

variable "enable_backup" {
  description = "Daily Azure Backup of the edge VM (~US$5–8/mo). The edge is also rebuildable from this code."
  type        = bool
  default     = true
}

variable "enable_budget" {
  description = "Resource-group budget alert. Azure for Students may not support budgets; leave false if apply fails."
  type        = bool
  default     = false
}

variable "budget_amount" {
  description = "Monthly budget in USD."
  type        = number
  default     = 40
}

variable "budget_start_date" {
  description = "First day of a month, RFC3339 (e.g. 2026-10-01T00:00:00Z)."
  type        = string
  default     = "2026-10-01T00:00:00Z"
}

variable "budget_contact_email" {
  type    = string
  default = ""
}

variable "tags" {
  type = map(string)
  default = {
    Project   = "linalg-tutor"
    Env       = "prod"
    ManagedBy = "opentofu"
  }
}
