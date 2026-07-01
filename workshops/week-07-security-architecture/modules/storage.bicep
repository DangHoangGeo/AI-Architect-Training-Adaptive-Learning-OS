param location string = resourceGroup().location
param namePrefix string
param replicationSku string = 'Standard_LRS'

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: toLower('${replace(namePrefix, '-', '')}${substring(uniqueString(resourceGroup().id), 0, 8)}')
  location: location
  sku: {
    name: replicationSku
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  name: 'default'
  parent: storage
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource data 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: 'data'
  parent: blobService
  properties: {
    publicAccess: 'None'
  }
}

output storageName string = storage.name
output storageId string = storage.id
