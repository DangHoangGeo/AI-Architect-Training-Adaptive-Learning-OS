// Week 04 complexity tier: blob versioning, lifecycle policy, soft delete retention
param location string = resourceGroup().location
param namePrefix string
param replicationSku string = 'Standard_LRS'

@description('Enable blob versioning for point-in-time restore. Required in prod.')
param enableBlobVersioning bool = false

@description('Days after which blobs are tiered to Cool. Set to 0 to disable.')
param tierToCoolAfterDays int = 0

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
    isVersioningEnabled: enableBlobVersioning
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

resource lifecyclePolicy 'Microsoft.Storage/storageAccounts/managementPolicies@2023-05-01' = if (tierToCoolAfterDays > 0) {
  name: 'default'
  parent: storage
  properties: {
    policy: {
      rules: [
        {
          name: 'tier-to-cool'
          enabled: true
          type: 'Lifecycle'
          definition: {
            filters: {
              blobTypes: ['blockBlob']
            }
            actions: {
              baseBlob: {
                tierToCool: {
                  daysAfterModificationGreaterThan: tierToCoolAfterDays
                }
              }
            }
          }
        }
      ]
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
