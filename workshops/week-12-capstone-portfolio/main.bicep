// Week 12 — Capstone: Executive-grade Architecture Portfolio
// Complexity tier: full modular library, private endpoints, diagnostic wiring, geo-replication stub,
//   multi-environment parameterization, cross-module output chaining, AI services
// This is the reference architecture the learner presents as their portfolio capstone.
// Every module used here should have been built or hardened across Weeks 1–11.

@description('Primary Azure region for all resources.')
param location string = resourceGroup().location

@description('Secondary region for geo-redundant components. Leave empty to deploy single-region.')
param secondaryLocation string = ''

@minLength(3)
@maxLength(18)
@description('Short prefix used in all resource names.')
param namePrefix string = 'aatos'

@allowed(['dev', 'test', 'prod'])
@description('Deployment environment. Controls all SKUs, replication, retention, and security settings.')
param environment string = 'dev'

@secure()
@description('SQL administrator password. Must be supplied via pipeline secret or parameter file.')
param sqlAdministratorPassword string

@allowed(['Basic', 'S1', 'S2', 'S3', 'P1', 'P2'])
@description('SQL service tier. Minimum S1 for production.')
param sqlServiceObjectiveName string = environment == 'prod' ? 'S1' : 'Basic'

@description('Enable AI services module. Set false to reduce cost in non-AI scenarios.')
param enableAiServices bool = true

// ─── Monitoring ─────────────────────────────────────────────────────────────
// First — every other module wires to its outputs

module monitoring './modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
    retentionInDays: environment == 'prod' ? 365 : 90
  }
}

// ─── Network ─────────────────────────────────────────────────────────────────
// Outputs consumed by KV private endpoint and Container Apps

module network './modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
  }
}

// ─── Storage ─────────────────────────────────────────────────────────────────

module storage './modules/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    namePrefix: '${namePrefix}${environment}'
    replicationSku: environment == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
  }
}

// ─── App Service ─────────────────────────────────────────────────────────────

module app './modules/webapp.bicep' = {
  name: 'webapp'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    skuName: environment == 'prod' ? 'P1v3' : 'B1'
  }
}

// ─── Key Vault ───────────────────────────────────────────────────────────────
// Capstone: fully private, audit logs, purge protection, private endpoint

module keyvault './modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
    principalObjectId: app.outputs.appPrincipalId
    privateEndpointSubnetId: network.outputs.privateEndpointSubnetId
    logAnalyticsWorkspaceId: monitoring.outputs.workspaceId
    softDeleteRetentionDays: environment == 'prod' ? 90 : 7
  }
}

// ─── Azure SQL ────────────────────────────────────────────────────────────────
// Capstone: service tier param, backup retention, audit logs, geo-replication stub

module sql './modules/sql.bicep' = {
  name: 'sql'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
    administratorLoginPassword: sqlAdministratorPassword
    serviceObjectiveName: sqlServiceObjectiveName
    backupRetentionDays: environment == 'prod' ? 35 : 7
    logAnalyticsWorkspaceId: monitoring.outputs.workspaceId
    secondaryLocation: secondaryLocation
  }
}

// ─── Service Bus Queue ────────────────────────────────────────────────────────

module queue './modules/queue.bicep' = {
  name: 'queue'
  params: {
    storageAccountName: storage.outputs.storageName
  }
}

// ─── Container Apps ───────────────────────────────────────────────────────────

module containerapp './modules/containerapp.bicep' = {
  name: 'containerapp'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
    logAnalyticsWorkspaceId: monitoring.outputs.workspaceId
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
  }
}

// ─── AI Services ─────────────────────────────────────────────────────────────
// Optional — disable for non-AI scenarios to avoid unnecessary quota consumption

module ai './modules/ai_services.bicep' = if (enableAiServices) {
  name: 'aiServices'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
  }
}

// ─── Outputs ─────────────────────────────────────────────────────────────────
// Capstone learner task: add outputs for every resource the ops team needs at deployment time

output applicationHostName string = app.outputs.defaultHostName
output storageAccountName string = storage.outputs.storageName
output logAnalyticsWorkspaceId string = monitoring.outputs.workspaceId
output sqlServerName string = sql.outputs.sqlServerName
output keyVaultUri string = keyvault.outputs.keyVaultUri
output containerAppName string = containerapp.outputs.containerAppName
