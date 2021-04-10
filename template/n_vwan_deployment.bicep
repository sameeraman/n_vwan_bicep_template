targetScope = 'subscription'

@description('vWAN Region Details Array')
param vWANRegionDetails array 

@description('Tags object to be applied on the resources')
param tags object 

@description('Short Prefix for the company name to be used in the resource naming. Eg: CTS for Contoso')
param companyPrefix string = 'CTS'

@description('Short code for the Environment to be used in the resource naming. Eg: PRD for Production')
param environment string = 'PRD'

// variables
var vmUserName = 'azureadmin'
var vmPassword = 'vm@${uniqueString(subscription().subscriptionId)}'
var vmDiagStgName = 'vmdiag${substring(uniqueString(subscription().subscriptionId, deployment().name),0,7)}'

// resources
resource rg0 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${companyPrefix}-${vWANRegionDetails[0].regionShortName}-${environment}-BICEP-VWAN'
  location: vWANRegionDetails[0].regionAzureLocation
  tags: tags
}

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = [for (region, i) in vWANRegionDetails: {
  name: '${companyPrefix}-${region.regionShortName}-${environment}-BICEP-NET'
  location: '${region.regionAzureLocation}'
  tags: tags
}]

module vnets '../resources/vNet_simple.bicep' = [for (region, i) in vWANRegionDetails: {
  name: 'vnet${i+1}'
  scope: rg[i]
  params: {
    vnetName: '${companyPrefix}-${region.regionShortName}-${environment}-VNET'
    vnetAddressSpace: region.regionVNetAddressSpace
    subnetAddressSpaces: [
      {
        subnetName: 'Server'
        subnetAddressSpace: region.regionVNetSubnetAddressSpace
      }
    ]
    tags: tags
  }
}]

module stg1 '../resources/storage_account.bicep' = {
  name: 'stg1'
  scope: rg0
  params: {
    stgName: vmDiagStgName
  }
}

module vms '../resources/vmSimple.bicep' = [for (region, i) in vWANRegionDetails: {
  name: '${region.regionShortName}VM1'
  scope: rg[i]
  params: {
    vmName: '${companyPrefix}${region.regionShortName}${environment}VM1'
    vnetName: vnets[i].outputs.vnetNameOutput
    vnetResourceGroupName: rg[i].name
    diagStorageUri: stg1.outputs.blobEndpoint
    createPublicIP: true
    adminUserName : vmUserName
    adminPassword: vmPassword
  }
}]


module vwan '../resources/vwan.bicep' = {
  name: 'vwan1'
  scope: rg0
  params: {
    wanname: '${companyPrefix}-${vWANRegionDetails[0].regionShortName}-${environment}-VWAN1'
  }
}

module vwanhubs '../resources/vwan_hub.bicep' = [ for (region,i) in vWANRegionDetails: {
  name: 'vwanhub${i+1}'
  scope: rg0
  params: {
    vwanid: vwan.outputs.id
    hubname: '${companyPrefix}-${region.regionShortName}-${environment}-VWAN-HUB'
    location: region.regionAzureLocation
    hubaddressprefix: region.regionVWANHubAddressSpace
  }
}]

module vwanhubconnection '../resources/vwan_hub_vnet_connection.bicep' = [for (region,i) in vWANRegionDetails: {
  name: 'vwanhub-${region.regionShortName}-connection'
  scope: rg0
  params: {
    vwanHubName: vwanhubs[i].outputs.name
    vnetId: vnets[i].outputs.id
    hubVnetConnectionName: '${region.regionShortName}-connection'
  }
}]


// outputs
output vmFQDN array = [for (region,i) in vWANRegionDetails: {
  vmName: vms[i].outputs.vmNameOut
  vmFQDN: vms[i].outputs.vmPublicFQDN
}]

output vmUsername string = vmUserName
output vmPassword string = vmPassword
