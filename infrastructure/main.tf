terraform {
  cloud {
    organization = "Ink-and-Ivy"
    workspaces {
      name = "production"
    }
  }

  required_version = ">= 1.12"

  required_providers {
    neon = {
      source  = "kislerdm/neon"
      version = "~> 0.9"
    }
    stripe = {
      source  = "lukasaron/stripe"
      version = "~> 3.3"
    }
  }
}

provider "neon" {
  api_key = var.neon_api_key
}

provider "stripe" {
  api_key = var.stripe_secret_key
}

locals {
  project_name = "ink-and-ivy"
  environment  = var.environment

  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}
