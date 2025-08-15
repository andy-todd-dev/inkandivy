# Database module variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "Neon region for database deployment"
  type        = string
  default     = "aws-us-east-1"
}

variable "database_name" {
  description = "Name of the main database"
  type        = string
  default     = "ink_and_ivy"
}

variable "database_owner" {
  description = "Database owner role name"
  type        = string
  default     = "ink_and_ivy_owner"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}