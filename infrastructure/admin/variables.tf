# Admin workspace input variables (supplied via env or tfvars, never commit secrets)

variable "neon_api_key" {
  description = "Neon API key to inject into production workspace"
  type        = string
  sensitive   = true
}

variable "stripe_secret_key" {
  description = "Stripe secret key to inject into production workspace"
  type        = string
  sensitive   = true
}


# Optional future variable
# variable "backend_url" {
#   description = "Backend service URL"
#   type        = string
#   default     = null
# }
