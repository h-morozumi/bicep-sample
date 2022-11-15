/**
 * Azure Studyで使用する最小限のAzure構成
 */
@description('仮想ネットワークの名前')
param virtualNetworkName string = 'AzureStudy-vnet'

@description('仮想ネットワークの IPv4 アドレス空間')
param virtualNetworkAddressPrefix string = '172.0.0.0/24'

@description('Windows 仮想マシンサブネットの名前')
param windowsVirtualMachineSubnetName string = 'Windows-VM-subnet'

@description('Windows 仮想マシンサブネットのアドレス範囲')
param windowsVirtualMachineSubnetPrefix string = '172.0.0.0/26'

@description('Windows 仮想マシンサブネットの NSG の名前')
param windowsVirtualMachineSubnetNSGName string = 'Windows-VM-nsg'

@description('Windows 仮想マシン管理者の名前')
param windowsAdminUserName string = 'azureuser'

@description('Windows 仮想マシンのパスワード')
@secure()
param windowsAdminPassword string

@allowed([
  '2008-R2-SP1'
  '2012-R2-Datacenter'
  '2016-Datacenter'
  '2019-Datacenter'
  '2019-Datacenter-Core'
  '2019-datacenter-core-g2'
  '2022-datacenter'
  '2022-datacenter-core'
  '2022-datacenter-core-g2'
  '2022-datacenter-g2'
  '2022-datacenter-smalldisk-g2'
  ])
@description('Windows Server の OS Version')
param windowsOSVersion string = '2022-datacenter-smalldisk-g2'

@allowed([
  'Standard_D2s_v5'
  'Standard_B2ms'
])
@description('Windows 仮想マシンのサイズ')
param windowsVirtualMachineSize string = 'Standard_B2ms'

@description('Windows 仮想マシンの NIC')
param windowsVirtualMachineNIC string = 'Windows-VM-nic'

@description('Windows 仮想マシンの名前')
param windowsVirtualMachineName string = 'Windows-VM'

@description('Windows 仮想マシンの Managed Disk のタイプ')
@allowed([
  'StandardSSD_LRS'
  'Standard_LRS'
  'Premium_LRS'
])
param windowsManagedDiskType string = 'StandardSSD_LRS'

@description('Linux 仮想マシンサブネットの名前')
param linuxVirtualMachineSubnetName string = 'Linux-VM-subnet'

@description('Linux 仮想マシンサブネットのアドレス範囲')
param linuxVirtualMachineSubnetPrefix string = '172.0.0.64/26'

@description('Linux 仮想マシンサブネットの NSG の名前')
param linuxVirtualMachineSubnetNSGName string = 'Linux-VM-nsg'

@description('Linux 仮想マシン管理者の名前')
param linuxAdminUserName string = 'azureuser'

@description('Linux 仮想マシンのパスワード')
@secure()
param linuxAdminPassword string

@allowed([
  '12.04.5-LTS'
  '14.04.5-LTS'
  '16.04.0-LTS'
  '18.04-LTS'
])
@description('Ubuntu Server の OS Version')
param ubuntuOSVersion string = '18.04-LTS'

@allowed([
  'Standard_D2s_v5'
  'Standard_B2ms'
])
@description('Linux 仮想マシンのサイズ')
param linuxVirtualMachineSize string = 'Standard_B2ms'

@description('Linux 仮想マシンの NIC')
param linuxVirtualMachineNIC string = 'Linux-VM-nic'

@description('Linux 仮想マシンの名前')
param linuxVirtualMachineName string = 'Linux-VM'

@allowed([
  'StandardSSD_LRS'
  'Standard_LRS'
  'Premium_LRS'
])
@description('Linux 仮想マシンの Managed Disk のタイプ')
param linuxManagedDiskType string = 'StandardSSD_LRS'


@description('Azure Bustion サブネットのアドレス範囲')
param azureBastionSubnetPrefix string = '172.0.0.128/26'

@description('Azure Bustion の名前')
param azureBastionHostName string = 'AzureBastionHost'

@description('Azure Bustion パブリック IP の名前')
param azureBastionPublicIP string = 'AzureBastion-pip'

@description('ロケーション')
param location string = resourceGroup().location

@description('Bastionのサブネット名は固定')
var azureBastionSubnetName = 'AzureBastionSubnet'

var windowsSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets',virtualNetworkName,windowsVirtualMachineSubnetName)
var linuxSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets',virtualNetworkName,linuxVirtualMachineSubnetName)


resource winNsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: windowsVirtualMachineSubnetNSGName
  location: location
}

resource linuxNgs 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: linuxVirtualMachineSubnetNSGName
  location: location
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name:virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: windowsVirtualMachineSubnetName
        properties: {
          addressPrefix:windowsVirtualMachineSubnetPrefix
          networkSecurityGroup: {
            id: winNsg.id
          }
        }
      }
      {
        name: linuxVirtualMachineSubnetName
        properties: {
          addressPrefix:linuxVirtualMachineSubnetPrefix
          networkSecurityGroup: {
            id: linuxNgs.id
          }
        }
      }
     {
        name:azureBastionSubnetName
        properties: {
          addressPrefix: azureBastionSubnetPrefix
        }
      } 
    ]
    
  }
}

resource basPip 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: azureBastionPublicIP
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource basHost 'Microsoft.Network/bastionHosts@2022-05-01' = {
  name: azureBastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'BastionIpconfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets',vnet.name,azureBastionSubnetName)
          }
          publicIPAddress: {
            id: basPip.id
          }
        }
      }
    ]
  }
}

resource winNic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: windowsVirtualMachineNIC
  location: location
  dependsOn: [
    vnet
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'WindowsIpconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: windowsSubnetRef
          }
        }
      }
    ]
    enableAcceleratedNetworking: false
  }
}

resource linuxNic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: linuxVirtualMachineNIC
  location: location
  dependsOn: [
    vnet
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'LinuxIpconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: linuxSubnetRef
          }
        }
      }
    ]
    enableAcceleratedNetworking: false
  }
}

resource win 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: windowsVirtualMachineName
  location: location
  zones: [
    '1'
  ]
  properties: {
    hardwareProfile: {
      vmSize: windowsVirtualMachineSize
    }
    osProfile: {
      computerName: windowsVirtualMachineName
      adminUsername: windowsAdminUserName
      adminPassword: windowsAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: windowsManagedDiskType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: winNic.id
        }
      ]
    }
  }
}

resource linux 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: linuxVirtualMachineName
  location: location
  zones: [
    '2'
  ]
  properties: {
    hardwareProfile: {
      vmSize: linuxVirtualMachineSize
    }
    osProfile: {
      computerName: linuxVirtualMachineName
      adminUsername: linuxAdminUserName
      adminPassword: linuxAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: ubuntuOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: linuxManagedDiskType
        }      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: linuxNic.id
        }
      ]
    }
  }
}

