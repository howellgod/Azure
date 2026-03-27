variable "subscription_id" {
  description = "Azure subscription ID used for deployment."
  type        = string
}

variable "location" {
  description = "Azure region for new resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment tag, for example dev, test, or prod."
  type        = string
}

variable "app_name" {
  description = "Short application name used in resource naming."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for new resources, or the name to create if create_resource_group is true."
  type        = string
}

variable "create_resource_group" {
  description = "When true, create the resource group for new resources."
  type        = bool
  default     = false
}

variable "data_factory_name" {
  description = "Optional explicit Data Factory name."
  type        = string
  default     = null
}

variable "deploy_key_vault" {
  description = "When true, deploy a Key Vault for connector secrets."
  type        = bool
  default     = true
}

variable "key_vault_name" {
  description = "Optional explicit Key Vault name."
  type        = string
  default     = null
}

variable "existing_sql_server_resource_group_name" {
  description = "Resource group containing the existing Azure SQL server."
  type        = string
}

variable "existing_sql_server_name" {
  description = "Name of the existing Azure SQL logical server."
  type        = string
}

variable "existing_sql_database_name" {
  description = "Name of the existing Azure SQL database."
  type        = string
}

variable "log_analytics_workspace_resource_id" {
  description = "Optional Log Analytics workspace resource ID for diagnostic settings."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all new resources."
  type        = map(string)
  default     = {}
}
