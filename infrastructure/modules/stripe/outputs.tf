# Stripe module outputs

output "webhook_endpoint_id" {
  description = "Stripe webhook endpoint ID (null if backend_url not provided)"
  value       = length(stripe_webhook_endpoint.medusa) > 0 ? stripe_webhook_endpoint.medusa[0].id : null
}

output "webhook_endpoint_secret" {
  description = "Stripe webhook endpoint secret (null if backend_url not provided)"
  value       = length(stripe_webhook_endpoint.medusa) > 0 ? stripe_webhook_endpoint.medusa[0].secret : null
  sensitive   = true
}

output "webhook_endpoint_url" {
  description = "Stripe webhook endpoint URL (null if backend_url not provided)"
  value       = length(stripe_webhook_endpoint.medusa) > 0 ? stripe_webhook_endpoint.medusa[0].url : null
}
