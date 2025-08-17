terraform {
  cloud {
    organization = "Ink-and-Ivy"
    workspaces {
      name = "infra-admin"
    }
  }

  required_version = ">= 1.12"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.68"
    }
  }
}

# Provider authenticates via TFE_TOKEN env var (recommended)
provider "tfe" {}

data "tfe_organization" "this" {
  name = "Ink-and-Ivy"
}

data "tfe_workspace" "production" {
  name         = "production"
  organization = data.tfe_organization.this.name
}

resource "tfe_variable" "neon_api_key" {
  workspace_id = data.tfe_workspace.production.id
  key          = "neon_api_key"
  value        = var.neon_api_key
  category     = "terraform"
  sensitive    = true
  hcl          = false
}

resource "tfe_variable" "stripe_secret_key" {
  workspace_id = data.tfe_workspace.production.id
  key          = "stripe_secret_key"
  value        = var.stripe_secret_key
  category     = "terraform"
  sensitive    = true
  hcl          = false
}
