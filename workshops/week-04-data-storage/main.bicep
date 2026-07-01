// Week 04 — Data and Storage Architecture
// Complexity tier: parameterized modules, allowedValues, output wiring, backup/retention per environment
// New vs Week 01-03: storage lifecycle, blob versioning, SQL service tier param, KV purge protection,
//   SQL audit logs wired to Log Analytics, environment-driven backup retention

@description('Azure region for all resources.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(18)
@description('Short prefix used in all resource names.')
param namePrefix string = 'aatos'

@allowed(['dev', 'test', 'prod'])
@description('Deployment environment. Controls SKUs, replication, retention, and backup policies.')
param environment string = 'dev'

@secure()
@description('SQL administrator password. Supply via pipeline secret — never hardcode.')
param sqlAdministratorPassword string

@allowed(['Basic', 'S1', 'S2', 'S3', 'P1', 'P2'])
@description('SQL service tier. S1 for standard prod, P1 for high-throughput. Basic for dev only.')
param sqlServiceObjectiveName string = environment == 'prod' ? 'S1' : 'Basic'

// --- Monitoring (first — other modules consume its outputs) ---

module monitoring './modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
    retentionInDays: environment == 'prod' ? 365 : 30
  }
}

// --- Network ---

module network './modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
  }
}

// --- Storage: replication + lifecycle policy driven by environment ---

module storage './modules/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    namePrefix: '${namePrefix}${environment}'
    replicationSku: environment == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
    enableBlobVersioning: environment == 'prod'
    tierToCoolAfterDays: environment == 'prod' ? 30 : 0
  }
}

// --- App Service (wires App Insights connection string from monitoring output) ---

module app './modules/webapp.bicep' = {
  name: 'webapp'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    skuName: environment == 'prod' ? 'P1v3' : 'B1'
  }
}

// --- Key Vault: purge protection and soft delete retention per environment ---

module keyvault './modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
    principalObjectId: app.outputs.appPrincipalId
    softDeleteRetentionDays: environment == 'prod' ? 90 : 7
    enablePurgeProtection: environment == 'prod'
  }
}

// --- Azure SQL: service tier, backup retention, audit logs wired to workspace ---

module sql './modules/sql.bicep' = {
  name: 'sql'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
    administratorLoginPassword: sqlAdministratorPassword
    serviceObjectiveName: sqlServiceObjectiveName
    backupRetentionDays: environment == 'prod' ? 35 : 7
    logAnalyticsWorkspaceId: environment == 'prod' ? monitoring.outputs.workspaceId : ''
  }
}

// --- Workshop learner task: Cosmos DB module ---
// Create modules/cosmos.bicep covering:
//   - Account with chosen consistency level (justify: Strong vs Session vs Eventual)
//   - Database and container with partition key design
//   - Throughput: provisioned (environment == 'prod') vs serverless (dev)
//   - Backup: continuous (prod) vs periodic (dev)
// Uncomment and implement after completing the module:
//
// module cosmos './modules/cosmos.bicep' = {
//   name: 'cosmos'
//   params: {
//     location: location
//     namePrefix: '${namePrefix}-${environment}'
//     consistencyLevel: 'Session'
//     partitionKeyPath: '/tenantId'
//     throughput: environment == 'prod' ? 1000 : 0   // 0 = serverless
//     enableContinuousBackup: environment == 'prod'
//   }
// }

// --- Outputs ---

output applicationHostName string = app.outputs.defaultHostName
output storageAccountName string = storage.outputs.storageName
output logAnalyticsWorkspaceId string = monitoring.outputs.workspaceId
output sqlServerFqdn string = sql.outputs.sqlServerFqdn
output keyVaultUri string = keyvault.outputs.keyVaultUri
