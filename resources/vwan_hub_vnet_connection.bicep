param hubVnetConnectionName string

@description('VWAN Hub Name')
param vwanHubName string 

@description('vnet ID to connect')
param vnetId string

resource hubvnetconnection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-08-01' = {
  name: '${vwanHubName}/${hubVnetConnectionName}'
  properties: {
    remoteVirtualNetwork: {
      id: vnetId
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: false
    enableInternetSecurity: true
  }
}

output id string = hubvnetconnection.id
output name string = hubvnetconnection.name
