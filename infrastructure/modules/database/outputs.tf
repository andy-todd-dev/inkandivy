# Database module outputs

output "connection_string" {
  description = "PostgreSQL connection string"
  value       = local.connection_string
  sensitive   = true
}

output "host" {
  description = "Database host"
  value       = neon_project.main.database_host
}

output "database_name" {
  description = "Database name"
  value       = neon_database.main.name
}

output "project_id" {
  description = "Neon project ID"
  value       = neon_project.main.id
}

output "branch_id" {
  description = "Neon branch ID"
  value       = neon_project.main.default_branch_id
}

output "app_user" {
  description = "Application database user"
  value       = neon_role.app_user.name
}

output "app_password" {
  description = "Application database password"
  value       = neon_role.app_user.password
  sensitive   = true
}