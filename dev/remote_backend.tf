terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  # Account details come from ../backend.hcl (terraform init -backend-config=../backend.hcl).
  # The key is the only per-environment value: change it when copying this folder.
  backend "azurerm" {
    key = "aks-clusters-weu/dev.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.81"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}
