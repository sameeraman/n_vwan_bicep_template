param stgName string 
param location string = resourceGroup().location
param kind string = 'StorageV2'
param globalRedundancy bool = false
param tags object = {}

var stgname = empty(stgName) ? 'stg${uniqueString(resourceGroup().id)}' : stgName 

resource stg1 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: stgname
  location: location
  kind: 'StorageV2'
  tags: tags
  sku:{
    name: globalRedundancy ? 'Standard_GRS' : 'Standard_LRS'
  }
}

output storageid string = stg1.id
output computedStorageAccountName string = stg1.name
output blobEndpoint string = stg1.properties.primaryEndpoints.blob
