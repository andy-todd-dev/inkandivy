# Stripe Configuration Module
# Manages Stripe webhook endpoints and payment configuration

terraform {
  required_providers {
    stripe = {
      source  = "lukasaron/stripe"
      version = "~> 3.3"
    }
  }
}

# Stripe webhook endpoint for Medusa integration (conditional)
resource "stripe_webhook_endpoint" "medusa" {
  count = var.backend_url != null ? 1 : 0
  
  url = "${var.backend_url}/stripe/webhooks"
  
  enabled_events = [
    "payment_intent.succeeded",
    "payment_intent.payment_failed",
    "payment_intent.amount_capturable_updated",
    "payment_intent.canceled",
    "payment_method.attached",
    "customer.created",
    "customer.updated",
    "invoice.payment_succeeded",
    "invoice.payment_failed"
  ]
  
  description = "Medusa e-commerce webhook endpoint"
  
  # API version for consistency (latest stable)
  api_version = "2025-07-30.basil"
}
