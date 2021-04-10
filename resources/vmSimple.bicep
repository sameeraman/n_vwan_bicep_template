param adminUserName string = 'azureadmin'

@secure()
param adminPassword string = '3RUwNf1spErujpfu3RqK'

param vmName string 
param windowsOSVersion string =  '2019-Datacenter'
param vmSize string = 'Standard_B2ms'
param location string = resourceGroup().location
param vnetName string = 'ADM-AUE-PRD-VNET1'
param vnetResourceGroupName string = resourceGroup().name
param subnetName string = 'Server'
param diagStorageAccountName string = 'admauediagst01'
param diagStorageAccountRGName string = resourceGroup().name
param diagStorageUri string 
param tags object = {}

param createPublicIP bool = false

var nicName = '${vmName}-NIC1'
var osDiskName = '${vmName}-DISK1'
var pipName = '${vmName}-PIP1'
var publicIPDns = '${toLower(vmName)}-${uniqueString(resourceGroup().id)}'
var subnetId = resourceId(vnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
// var diagStorageId = resourceId('Microsoft.Storage/storageAccounts', diagStorageAccountName)

resource publicIP 'Microsoft.Network/publicIPAddresses@2017-09-01' = if (createPublicIP) {
  name: pipName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: publicIPDns
    }
  }
}



resource nInter 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
          publicIPAddress: any(createPublicIP ? {
            id : publicIP.id
          } : null)
        }
      }
    ]
  }

}

resource VM 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    licenseType: 'Windows_Server'
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUserName
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nInter.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: diagStorageUri
      }
    }
  }
}

output vmNameOut string = vmName
output vmPrivateIP string = nInter.properties.ipConfigurations[0].properties.privateIPAddress
output vmPublicFQDN string = any(createPublicIP ? publicIP.properties.dnsSettings.fqdn : null)
