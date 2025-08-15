# Core Infrastructure Outputs
# Deployment services managed by GitHub Actions

output "database_connection_string" {
  description = "PostgreSQL database connection string for application use"
  value       = module.database.connection_string
  sensitive   = true
}

output "database_host" {
  description = "Database host for application configuration"
  value       = module.database.host
}

output "database_name" {
  description = "Database name"
  value       = module.database.database_name
}

output "stripe_webhook_endpoint_id" {
  description = "Stripe webhook endpoint ID (null if backend not deployed yet)"
  value       = module.stripe.webhook_endpoint_id
}

output "stripe_webhook_secret" {
  description = "Stripe webhook endpoint secret (null if backend not deployed yet)"
  value       = module.stripe.webhook_endpoint_secret
  sensitive   = true
}

output "stripe_webhook_configured" {
  description = "Whether Stripe webhook is configured"
  value       = var.backend_url != null
}

# Core environment variables that GitHub Actions will use for deployments
output "core_env_vars" {
  description = "Core environment variables for GitHub Actions deployments"
  value = {
    # Database
    DATABASE_URL = module.database.connection_string
    
    # Stripe
    STRIPE_SECRET_KEY     = var.stripe_secret_key
    STRIPE_WEBHOOK_SECRET = module.stripe.webhook_endpoint_secret  # Will be null initially
    
    # Project info
    PROJECT_NAME = local.project_name
    ENVIRONMENT  = local.environment
  }
  sensitive = true
}