terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

provider "azurerm" {
  features {}
  client_id               = var.client_id
  subscription_id         = var.subscription_id
  tenant_id               = var.tenant_id
  client_certificate_path = var.client_certificate_path
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
