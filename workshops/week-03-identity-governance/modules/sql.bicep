param location string = resourceGroup().location
param namePrefix string
@secure()
param administratorLoginPassword string
param administratorLogin string = 'sqladminuser'

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
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    maxSizeBytes: 2147483648
  }
}

output sqlServerName string = server.name
output databaseName string = database.name
