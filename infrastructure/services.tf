# Core Infrastructure Services Configuration
# Deployment services (Vercel, Render) handled by GitHub Actions

# Database module - Core infrastructure that needs Terraform
module "database" {
  source = "./modules/database"
  
  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags
}

# Stripe configuration module - Webhooks and payment setup
module "stripe" {
  source = "./modules/stripe"
  
  project_name = local.project_name
  environment  = local.environment
  backend_url  = var.backend_url  # Optional - webhook created only if provided
  tags         = local.common_tags
  
  depends_on = [module.database]
}