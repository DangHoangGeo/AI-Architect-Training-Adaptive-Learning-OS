param location string = resourceGroup().location
@minLength(3)
@maxLength(18)
param namePrefix string = 'aatos'
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@secure()
@description('SQL administrator password. Supply securely at deployment time, never commit a real value.')
param sqlAdministratorPassword string

module monitoring './modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
    retentionInDays: environment == 'prod' ? 90 : 30
  }
}

module network './modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
  }
}

module storage './modules/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    namePrefix: '${namePrefix}${environment}'
    replicationSku: environment == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
  }
}

module app './modules/webapp.bicep' = {
  name: 'webapp'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    skuName: environment == 'prod' ? 'P1v3' : 'B1'
  }
}

module keyvault './modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
    principalObjectId: app.outputs.appPrincipalId
  }
}


module queue './modules/queue.bicep' = {
  name: 'queue'
  params: {
    storageAccountName: storage.outputs.storageName
  }
}


module sql './modules/sql.bicep' = {
  name: 'sql'
  params: {
    location: location
    namePrefix: '${namePrefix}-${environment}'
    administratorLoginPassword: sqlAdministratorPassword
  }
}


output applicationHostName string = app.outputs.defaultHostName
output storageAccountName string = storage.outputs.storageName
output logAnalyticsWorkspaceId string = monitoring.outputs.workspaceId
