terraform {
  required_version = ">= 1.8.0" # OpenTofu

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Remote state in the storage account created by hand in the getting-started step 5.
  # Values come from backend.hcl:  tofu init -backend-config=backend.hcl
  backend "azurerm" {}
}
