param location string = resourceGroup().location
param namePrefix string

resource search 'Microsoft.Search/searchServices@2023-11-01' = {
  name: '${namePrefix}-srch-${substring(uniqueString(resourceGroup().id), 0, 4)}'
  location: location
  sku: {
    name: 'basic'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: 'enabled'
  }
}

resource cognitive 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: '${namePrefix}-cog-${substring(uniqueString(resourceGroup().id), 0, 4)}'
  location: location
  kind: 'CognitiveServices'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

output searchName string = search.name
output cognitiveAccountName string = cognitive.name
