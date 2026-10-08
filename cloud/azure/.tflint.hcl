plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "azurerm" {
  enabled = true
  version = "0.28.0" # check https://github.com/terraform-linters/tflint-ruleset-azurerm/releases
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}
