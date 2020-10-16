# LAB 02: Create a virtual network and its subnets

<#
In this lab, we will create a virtual network with 3 subnets.
In 'jumpbox' subnet, we will later deploy the Linux jumpbox virtual machine.
In 'management' subnet, a Windows management virtual machine.
And finally, in 'frontend' subnet a couple of Windows virtual machines as part of the VM Scale Set. 
#>


#region Define variables

$resourceGroupName = 'espc20-rg'
$vnetName = 'demovnet'
$location = 'westeurope'

#endregion

#region Authenticate to Azure

Connect-AzAccount

#endregion


#region Create a VNet with the jumpbox, management, and frontend subnets

New-AzResourceGroup -Name $resourceGroupName -Location $location

$vnet = New-AzVirtualNetwork -Name $vnetName -AddressPrefix 192.168.0.0/16 -ResourceGroupName $resourceGroupName -Location $location

$subnetConfigJb = New-AzVirtualNetworkSubnetConfig -Name jumpbox -AddressPrefix 192.168.1.0/29
$vnet.Subnets.Add($subnetConfigJb)
Set-AzVirtualNetwork -VirtualNetwork $vnet

$subnetConfigMgmt = New-AzVirtualNetworkSubnetConfig -Name management -AddressPrefix 192.168.2.0/24
$vnet.Subnets.Add($subnetConfigMgmt)
Set-AzVirtualNetwork -VirtualNetwork $vnet


$subnetConfigMgmt = New-AzVirtualNetworkSubnetConfig -Name frontend -AddressPrefix 192.168.3.0/24
$vnet.Subnets.Add($subnetConfigMgmt)
Set-AzVirtualNetwork -VirtualNetwork $vnet

#endregion

<#
The goal is to secure network access so that only a jumpbox machine has a public IP address.
To accomplish that we will create a couple of network security groups and assign them to the subnets.
Allowed traffic:
1. From internet allow SSH to a jumpbox machine
2. Allow RDP to a Windows management machine only from the jumpbox machine
3. From internet allow access to port 80 on web servers in a VM scale set 
#>

#region Create the network security groups (NSGs)

$ssh = New-AzNetworkSecurityRuleConfig -Name "allow-SSH-from-internet" -SourcePortRange * -Protocol TCP -SourceAddressPrefix Internet -Access Allow -Priority 120 -Direction Inbound -DestinationPortRange 22 -DestinationAddressPrefix *
$rdp = New-AzNetworkSecurityRuleConfig -Name "allow-RDP-from-jumpbox" -SourcePortRange * -Protocol TCP -SourceAddressPrefix "192.168.1.0/29" -Access Allow -Priority 110 -Direction Inbound -DestinationPortRange 3389 -DestinationAddressPrefix *
$web = New-AzNetworkSecurityRuleConfig -Name "allow-80-from-internet" -SourcePortRange * -Protocol TCP -SourceAddressPrefix Internet -Access Allow -Priority 200 -Direction Inbound -DestinationPortRange 80 -DestinationAddressPrefix *

New-AzNetworkSecurityGroup -Name management -SecurityRules $rdp -ResourceGroupName $resourceGroupName -Location $location
New-AzNetworkSecurityGroup -Name jumpbox -SecurityRules $ssh -ResourceGroupName $resourceGroupName -Location $location
New-AzNetworkSecurityGroup -Name frontend -SecurityRules $web -ResourceGroupName $resourceGroupName -Location $location

$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName

$nsg = Get-AzNetworkSecurityGroup -Name jumpbox -ResourceGroupName $resourceGroupName
$subnet = Get-AzVirtualNetworkSubnetConfig -Name jumpbox -VirtualNetwork $vnet
$vnetConfig = Set-AzVirtualNetworkSubnetConfig -Name jumpbox -VirtualNetwork $vnet -NetworkSecurityGroup $nsg -AddressPrefix $subnet.AddressPrefix
Set-AzVirtualNetwork -VirtualNetwork $vnetConfig

$nsg = Get-AzNetworkSecurityGroup -Name management -ResourceGroupName $resourceGroupName
$subnet = Get-AzVirtualNetworkSubnetConfig -Name management -VirtualNetwork $vnet
$vnetConfig = Set-AzVirtualNetworkSubnetConfig -Name management -VirtualNetwork $vnet -NetworkSecurityGroup $nsg -AddressPrefix $subnet.AddressPrefix
Set-AzVirtualNetwork -VirtualNetwork $vnetConfig

$nsg = Get-AzNetworkSecurityGroup -Name frontend -ResourceGroupName $resourceGroupName
$subnet = Get-AzVirtualNetworkSubnetConfig -Name frontend -VirtualNetwork $vnet
$vnetConfig = Set-AzVirtualNetworkSubnetConfig -Name frontend -VirtualNetwork $vnet -NetworkSecurityGroup $nsg -AddressPrefix $subnet.AddressPrefix
Set-AzVirtualNetwork -VirtualNetwork $vnetConfig

#endregion