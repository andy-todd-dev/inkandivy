# Variables for Ink and Ivy Infrastructure
# Only variables actually used by Terraform

variable "environment" {
  description = "Environment name (production)"
  type        = string
  default     = "production"
}

# Core infrastructure API tokens
variable "neon_api_key" {
  description = "Neon API key for PostgreSQL database management"
  type        = string
  sensitive   = true
}

variable "stripe_secret_key" {
  description = "Stripe secret key for payment processing"
  type        = string
  sensitive   = true
}

# Optional backend URL for Stripe webhook (set after deployment)
variable "backend_url" {
  description = "Backend service URL for Stripe webhook configuration (optional)"
  type        = string
  default     = null
}