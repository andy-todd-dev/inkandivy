# Neon PostgreSQL Database Module
# Manages database provisioning and configuration

terraform {
  required_providers {
    neon = {
      source  = "kislerdm/neon"
      version = "~> 0.9"
    }
  }
}

# Neon project for the database
resource "neon_project" "main" {
  name                = var.project_name
  region_id           = var.region
  default_branch_name = var.environment
  
  # Note: Free tier limits are automatically applied by Neon
  # No explicit quota configuration needed for free tier
}

# Main database within the project
resource "neon_database" "main" {
  project_id = neon_project.main.id
  branch_id  = neon_project.main.default_branch_id
  name       = var.database_name
  owner_name = var.database_owner
}

# Database role for application access
resource "neon_role" "app_user" {
  project_id = neon_project.main.id
  branch_id  = neon_project.main.default_branch_id
  name       = "${var.project_name}_app"
}

# Connection string construction
locals {
  connection_string = "postgresql://${neon_role.app_user.name}:${neon_role.app_user.password}@${neon_project.main.database_host}/${neon_database.main.name}?sslmode=require"
}