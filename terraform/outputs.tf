output "deployment_resource_group_name" {
  description = "Resource group hosting the newly provisioned resources."
  value       = local.deployment_resource_group_name
}

output "data_factory_name" {
  description = "Azure Data Factory name."
  value       = azurerm_data_factory.this.name
}

output "data_factory_id" {
  description = "Azure Data Factory resource ID."
  value       = azurerm_data_factory.this.id
}

output "data_factory_managed_identity_principal_id" {
  description = "Principal ID for the Data Factory system-assigned managed identity."
  value       = azurerm_data_factory.this.identity[0].principal_id
}

output "existing_sql_server_id" {
  description = "Referenced existing Azure SQL server ID."
  value       = data.azurerm_mssql_server.existing.id
}

output "existing_sql_server_fqdn" {
  description = "Referenced existing Azure SQL fully qualified domain name."
  value       = data.azurerm_mssql_server.existing.fully_qualified_domain_name
}

output "existing_sql_database_id" {
  description = "Referenced existing Azure SQL database ID."
  value       = data.azurerm_mssql_database.existing.id
}

output "key_vault_name" {
  description = "Key Vault name when deployed."
  value       = var.deploy_key_vault ? azurerm_key_vault.this[0].name : null
}
