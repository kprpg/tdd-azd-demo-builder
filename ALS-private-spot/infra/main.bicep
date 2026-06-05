targetScope = 'resourceGroup'

@description('Deployment environment name from AZURE_ENV_NAME.')
param environment string

@description('Project slug used in resource names.')
param projectName string = 'als-private-spot'

@description('Azure region for resources.')
param location string = resourceGroup().location

@description('SSH public key for jumpbox VM.')
@minLength(1)
param jumpboxSshPublicKey string

@description('Admin username for jumpbox VM.')
@minLength(1)
param jumpboxAdminUsername string = 'azureuser'

@description('VM size for AKS system node pool.')
param systemNodeVmSize string = 'Standard_B2s'

@description('VM size for AKS Spot user node pool.')
param userSpotNodeVmSize string = 'Standard_B2s'

var uniqueSuffix = uniqueString(resourceGroup().id)
var tags = {
  Environment: environment
  ManagedBy: 'Bicep'
  Project: projectName
  SecurityControl: 'Ignore'
}

var vnetName = 'vnet-${projectName}-${environment}'
var aksSubnetName = 'snet-aks-${environment}'
var bastionSubnetName = 'AzureBastionSubnet'
var jumpboxSubnetName = 'snet-jumpbox-${environment}'

var bastionPipName = 'pip-bastion-${environment}-${take(uniqueSuffix, 5)}'
var bastionName = 'bas-${projectName}-${environment}'
var jumpboxNicName = 'nic-jumpbox-${environment}'
var jumpboxName = 'vm-jumpbox-${environment}'
var aksName = 'aks-${projectName}-${environment}'

resource rgTags 'Microsoft.Resources/tags@2024-03-01' = {
  name: 'default'
  properties: {
    tags: tags
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.20.0.0/16'
      ]
    }
    subnets: [
      {
        name: aksSubnetName
        properties: {
          addressPrefix: '10.20.1.0/24'
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: '10.20.2.0/26'
        }
      }
      {
        name: jumpboxSubnetName
        properties: {
          addressPrefix: '10.20.3.0/24'
        }
      }
    ]
  }
}

resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: bastionPipName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: bastionName
  location: location
  tags: tags
  dependsOn: [
    vnet
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-ipconfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, bastionSubnetName)
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }
}

resource jumpboxNic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: jumpboxNicName
  location: location
  tags: tags
  dependsOn: [
    vnet
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, jumpboxSubnetName)
          }
        }
      }
    ]
  }
}

resource jumpboxVm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: jumpboxName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: jumpboxName
      adminUsername: jumpboxAdminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${jumpboxAdminUsername}/.ssh/authorized_keys'
              keyData: jumpboxSshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jumpboxNic.id
        }
      ]
    }
  }
}

resource jumpboxTools 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  parent: jumpboxVm
  name: 'install-aks-tools'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'bash -c "apt-get update && apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg && curl -sL https://aka.ms/InstallAzureCLIDeb | bash && az aks install-cli"'
    }
  }
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-09-01' = {
  name: aksName
  location: location
  tags: tags
  dependsOn: [
    vnet
  ]
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  properties: {
    dnsPrefix: 'aks-${take(uniqueSuffix, 8)}'
    nodeResourceGroup: 'rg-${projectName}-nodes-${environment}'
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'sysnp'
        mode: 'System'
        count: 1
        vmSize: systemNodeVmSize
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, aksSubnetName)
        enableAutoScaling: false
      }
      {
        name: 'spotnp'
        mode: 'User'
        minCount: 0
        maxCount: 2
        count: 1
        vmSize: userSpotNodeVmSize
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, aksSubnetName)
        enableAutoScaling: true
        scaleSetPriority: 'Spot'
        scaleSetEvictionPolicy: 'Delete'
        spotMaxPrice: -1
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      podCidr: '10.244.0.0/16'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
      outboundType: 'loadBalancer'
    }
    apiServerAccessProfile: {
      enablePrivateCluster: true
      privateDNSZone: 'system'
      enablePrivateClusterPublicFQDN: false
    }
  }
}

output aksClusterName string = aksCluster.name
output bastionName string = bastionHost.name
output jumpboxVmName string = jumpboxVm.name
output jumpboxUser string = jumpboxAdminUsername
output resourceGroupName string = resourceGroup().name
