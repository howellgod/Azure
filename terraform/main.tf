locals {
  normalized_app_name = lower(replace(var.app_name, "_", "-"))
  common_tags = merge(
    {
      application = var.app_name
      environment = var.environment
      managed_by  = "terraform"
      workload    = "powerbi-workbook-ingestion"
    },
    var.tags
  )
}

resource "azurerm_resource_group" "this" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

data "azurerm_resource_group" "existing_target" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

data "azurerm_resource_group" "existing_sql" {
  name = var.existing_sql_server_resource_group_name
}

data "azurerm_client_config" "current" {}

locals {
  deployment_resource_group_name = var.create_resource_group ? azurerm_resource_group.this[0].name : data.azurerm_resource_group.existing_target[0].name
  deployment_resource_group_id   = var.create_resource_group ? azurerm_resource_group.this[0].id : data.azurerm_resource_group.existing_target[0].id
  data_factory_name              = coalesce(var.data_factory_name, "adf-${local.normalized_app_name}-${var.environment}")
  key_vault_name                 = coalesce(var.key_vault_name, "kv-${local.normalized_app_name}-${var.environment}")
}

data "azurerm_mssql_server" "existing" {
  name                = var.existing_sql_server_name
  resource_group_name = data.azurerm_resource_group.existing_sql.name
}

data "azurerm_mssql_database" "existing" {
  name      = var.existing_sql_database_name
  server_id = data.azurerm_mssql_server.existing.id
}

resource "azurerm_data_factory" "this" {
  name                = local.data_factory_name
  location            = var.location
  resource_group_name = local.deployment_resource_group_name

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

resource "azurerm_key_vault" "this" {
  count               = var.deploy_key_vault ? 1 : 0
  name                = local.key_vault_name
  location            = var.location
  resource_group_name = local.deployment_resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  tags = local.common_tags
}

resource "azurerm_key_vault_access_policy" "current_user" {
  count        = var.deploy_key_vault ? 1 : 0
  key_vault_id = azurerm_key_vault.this[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge",
    "Recover"
  ]
}

resource "azurerm_key_vault_access_policy" "data_factory" {
  count        = var.deploy_key_vault ? 1 : 0
  key_vault_id = azurerm_key_vault.this[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_data_factory.this.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

resource "azurerm_monitor_diagnostic_setting" "data_factory" {
  count                      = var.log_analytics_workspace_resource_id == null ? 0 : 1
  name                       = "diag-${azurerm_data_factory.this.name}"
  target_resource_id         = azurerm_data_factory.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_resource_id

  enabled_log {
    category = "ActivityRuns"
  }

  enabled_log {
    category = "PipelineRuns"
  }

  enabled_log {
    category = "TriggerRuns"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
