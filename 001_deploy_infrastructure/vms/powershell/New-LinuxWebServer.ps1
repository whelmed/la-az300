$resourceGroup = "VMDemoPowerShell"
$location = "EastUS"
$image = "UbuntuLTS"
$networkName = "power-shell-linux-vnet"

New-AzureRmResourceGroup -Name $resourceGroup -Location $location

$vnet = New-AzureRmVirtualNetwork `
    -Name $networkName `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -AddressPrefix "10.0.0.0/16" 

$defaultSubnet = Add-AzureRmVirtualNetworkSubnetConfig -Name "default" -AddressPrefix "10.0.0.0/24" -VirtualNetwork $vnet

# Create the subnet
$vnet | Set-AzureRmVirtualNetwork
$pip = New-AzureRmPublicIpAddress -Name "vm-ps-demo-pip" -ResourceGroupName $resourceGroup -Location $location -AllocationMethod Dynamic

$vm = New-AzureRmVm `
    -ResourceGroupName $resourceGroup `
    -Name "UbuntuPowerShellDemo" `
    -Image $image `
    -Location $location `
    -VirtualNetworkName $networkName `
    -SubnetName $defaultSubnet.Name `
    -SecurityGroupName "power-shell-linux-vnet-nsg" `
    -PublicIpAddressName $pip.Name `
    -OpenPorts 80

Set-AzureRmVMExtension `
    -ResourceGroupName $resourceGroup `
    -ExtensionName "bootstrap" `
    -VMName $vm.Name `
    -Location $location `
    -Publisher "Microsoft.Azure.Extensions"  `
    -Type customScript `
    -TypeHandlerVersion "2.0" `
    -SettingString '{"commandToExecute":"sudo apt-get update -y; sudo apt-get install apache2 -y"}'


# Clean up by running
# Remove-AzureRmResourceGroup -Name YourResourceGroupNameHere