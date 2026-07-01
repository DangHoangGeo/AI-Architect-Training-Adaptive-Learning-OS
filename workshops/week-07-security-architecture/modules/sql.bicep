// Week 07 complexity tier: service tier param, backup retention, audit logs, always-on diagnostics
param location string = resourceGroup().location
param namePrefix string

@secure()
param administratorLoginPassword string
param administratorLogin string = 'sqladminuser'

@allowed(['Basic', 'S1', 'S2', 'S3', 'P1', 'P2'])
@description('SQL database service tier.')
param serviceObjectiveName string = 'Basic'

@minValue(1)
@maxValue(35)
@description('Short-term backup retention in days.')
param backupRetentionDays int = 7

@description('Log Analytics workspace resource ID for SQL audit log streaming.')
param logAnalyticsWorkspaceId string = ''

resource server 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: '${namePrefix}-sql-${substring(uniqueString(resourceGroup().id), 0, 5)}'
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
  }
}

resource database 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  name: 'appdb'
  parent: server
  location: location
  sku: {
    name: serviceObjectiveName
    tier: startsWith(serviceObjectiveName, 'P') ? 'Premium' : (serviceObjectiveName == 'Basic' ? 'Basic' : 'Standard')
  }
  properties: {
    maxSizeBytes: 2147483648
  }
}

resource backupPolicy 'Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies@2023-08-01-preview' = {
  name: 'default'
  parent: database
  properties: {
    retentionDays: backupRetentionDays
  }
}

resource auditSettings 'Microsoft.Sql/servers/auditingSettings@2023-08-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'default'
  parent: server
  properties: {
    state: 'Enabled'
    isAzureMonitorTargetEnabled: true
  }
}

output sqlServerName string = server.name
output sqlServerFqdn string = server.properties.fullyQualifiedDomainName
output databaseName string = database.name
