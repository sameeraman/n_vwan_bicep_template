
param vnetName string = 'ADM-AUE-PRD-VNET1'
param vnetAddressSpace string = '10.0.0.0/22'
param subnetAddressSpaces array = [
  {
    subnetName: 'Server'
    subnetAddressSpace:'10.0.0.0/24'
  }
]
param tags object = {}


resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: resourceGroup().location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    enableVmProtection: false
    enableDdosProtection: false
    subnets: [for i in subnetAddressSpaces: {
      name: i.subnetName
      properties: {
          addressPrefix: i.subnetAddressSpace
        }
    }]
  }
}

output vnetNameOutput string = vnetName
output id string = vnet.id
