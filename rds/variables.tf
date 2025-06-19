variable "environment" {
  description = "The environment for which the resources are being created (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "db_name" {
  description = "The name of the database to create."
  type        = string
  default     = "telehealth"
}

variable "db_username" {
  description = "Master username for the database."
  type        = string
  default     = "telehealth"
}

variable "instance_count" {
  description = "Number of Aurora DB instances to create."
  type        = number
  default     = 1
}