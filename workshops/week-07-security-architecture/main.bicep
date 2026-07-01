// Week 07 — Security Architecture and Threat Modeling
// Complexity tier: private endpoints, managed identity roleAssignments, diagnostic logs,
//   public network disabled on KV, network-isolated SQL, audit log wiring
// New vs Week 04: Key Vault is fully private (no public access), diagnostic settings on KV,
//   private endpoint for KV, SQL audit logs always enabled, network module outputs consumed by KV module

@description('Azure region for all resources.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(18)
@description('Short prefix used in all resource names.')
param namePrefix string = 'aatos'

@allowed(['dev', 'test', 'prod'])
param environment string = 'dev'

@secure()
@description('SQL administrator password. Supply via pipeline secret.')
param sqlAdministratorPassword string

@allowed(['Basic', 'S1', 'S2', 'S3', 'P1', 'P2'])
param sqlServiceObjectiveName string = environment == 'prod' ? 'S1' : 'Basic'

// --- Monitoring (first — other modules consume its outputs) ---

module monitoring './modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
    retentionInDays: environment == 'prod' ? 365 : 90  // Week 07: security logs need longer retention
  }
}

// --- Network: outputs consumed downstream by KV private endpoint ---

module network './modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
  }
}

// --- Storage ---

module storage './modules/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    namePrefix: '${namePrefix}${environment}'
    replicationSku: environment == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
  }
}

// --- App Service ---

module app './modules/webapp.bicep' = {
  name: 'webapp'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    skuName: environment == 'prod' ? 'P1v3' : 'B1'
  }
}

// --- Key Vault: Week 07 new features
//   - publicNetworkAccess: Disabled
//   - private endpoint in snet-private-endpoints
//   - diagnostic logs to Log Analytics
//   - purge protection + 90-day soft delete

module keyvault './modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
    principalObjectId: app.outputs.appPrincipalId
    // Week 07: network module outputs consumed here — this is output-wiring across modules
    privateEndpointSubnetId: network.outputs.privateEndpointSubnetId
    logAnalyticsWorkspaceId: monitoring.outputs.workspaceId
  }
}

// --- Azure SQL: audit logs always on in Week 07 ---

module sql './modules/sql.bicep' = {
  name: 'sql'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
    administratorLoginPassword: sqlAdministratorPassword
    serviceObjectiveName: sqlServiceObjectiveName
    backupRetentionDays: environment == 'prod' ? 35 : 7
    logAnalyticsWorkspaceId: monitoring.outputs.workspaceId
  }
}

// --- Outputs ---
// Week 07 learner task: add outputs for private endpoint IDs and NSG rule compliance status

output applicationHostName string = app.outputs.defaultHostName
output storageAccountName string = storage.outputs.storageName
output logAnalyticsWorkspaceId string = monitoring.outputs.workspaceId
output sqlServerName string = sql.outputs.sqlServerName
output keyVaultUri string = keyvault.outputs.keyVaultUri
output privateEndpointId string = keyvault.outputs.privateEndpointId
