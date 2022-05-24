data "azurerm_resource_group" "sample" {
  name     = "woordurff_Sawyer"
}
resource "azurerm_storage_account" "inbox" {
  name                      = "manish2"
  resource_group_name       = "woordurff_Sawyer"
  location                  = "East US"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind              = "StorageV2"
}
resource "azurerm_storage_container" "storagecontainer" {
  name                  = "cont"
  storage_account_name  = azurerm_storage_account.inbox.name
  container_access_type = "private"
}
resource "azurerm_storage_container" "storagecont" {
  name                  = "cont2"
  storage_account_name  = azurerm_storage_account.inbox.name
  container_access_type = "private"
}

resource "azurerm_application_insights" "logging" {
  name                = "blob-ai"
  location            = "East US"
  resource_group_name = "woordurff_Sawyer"
  application_type    = "web"
  retention_in_days   = 90
}
data "archive_file" "file_function_app" {
  type        = "zip"
  source_dir  = "C:/Users/Quadrant/OneDrive - Quadrant Resource LLC/Documents/sample/Project9/Function/bin/Debug/netcoreapp3.1/publish"
  output_path = "C:/Users/Quadrant/OneDrive - Quadrant Resource LLC/Documents/sample/Project9/Function/bin/Debug/netcoreapp3.1/publish/blob.zip"
}
resource "azurerm_storage_blob" "appcode" {
  name = "blobupload.zip"
  storage_account_name = azurerm_storage_account.inbox.name
  storage_container_name = azurerm_storage_container.storagecontainer.name
  type = "Block"
  source = "C:/Users/Quadrant/OneDrive - Quadrant Resource LLC/Documents/sample/Project9/Function/bin/Debug/netcoreapp3.1/publish/blob.zip"
}
data "azurerm_storage_account_blob_container_sas" "storage_account_blob_container_sas" {
  connection_string = azurerm_storage_account.inbox.primary_connection_string
  container_name    = azurerm_storage_container.storagecontainer.name

  start = "2021-11-01T00:00:00Z"
  expiry = "2023-01-01T00:00:00Z"

  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = true
    list   = true
  }
}

resource "azurerm_app_service_plan" "fxnapp" {
  name                = "blob-fxn-plan"
  location            = "East US"
  resource_group_name = "woordurff_Sawyer"
  kind                = "functionapp"
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}
resource "azurerm_function_app" "fsn" {
  name                       = "ManishBlobFunction"
  location                   = "East Us"
  resource_group_name        = "woordurff_Sawyer"
  app_service_plan_id        = azurerm_app_service_plan.fxnapp.id

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"    = "https://${azurerm_storage_account.inbox.name}.blob.core.windows.net/${azurerm_storage_container.storagecontainer.name}/${azurerm_storage_blob.appcode.name}${data.azurerm_storage_account_blob_container_sas.storage_account_blob_container_sas.sas}",
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet",
    "AzureWebJobsDisableHomepage" = "true",
    AppInsights_InstrumentationKey = azurerm_application_insights.logging.instrumentation_key
  }
  
os_type = "linux"
  site_config {
    use_32_bit_worker_process = false
  }
  storage_account_name       = azurerm_storage_account.inbox.name
  storage_account_access_key = azurerm_storage_account.inbox.primary_access_key
  version                    = "~3"



  # We ignore these because they're set/changed by Function deployment
  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"]
    ]
  }
}
