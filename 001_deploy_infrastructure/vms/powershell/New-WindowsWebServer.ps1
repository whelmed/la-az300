$resourceGroup = "WinVMDemoPowerShell"
$location = "EastUS"
$image = "MicrosoftWindowsServer:WindowsServer:2016-Datacenter:latest"
$networkName = "power-shell-win-vnet"

New-AzureRmResourceGroup -Name $resourceGroup -Location $location

$vnet = New-AzureRmVirtualNetwork `
    -Name $networkName `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -AddressPrefix "10.0.0.0/16" 

$defaultSubnet = Add-AzureRmVirtualNetworkSubnetConfig -Name "default" -AddressPrefix "10.0.0.0/24" -VirtualNetwork $vnet

# Create the subnet
$vnet | Set-AzureRmVirtualNetwork
$pip = New-AzureRmPublicIpAddress -Name "vm-ps-win-demo-pip" -ResourceGroupName $resourceGroup -Location $location -AllocationMethod Dynamic

$vm = New-AzureRmVm `
    -ResourceGroupName $resourceGroup `
    -Name "WinPSDemo" `
    -Image $image `
    -Location $location `
    -VirtualNetworkName $networkName `
    -SubnetName $defaultSubnet.Name `
    -SecurityGroupName "power-shell-win-vnet-nsg" `
    -PublicIpAddressName $pip.Name `
    -OpenPorts 80

Set-AzureRmVMExtension -ResourceGroupName "WinVMDemoPowerShell" `
    -ExtensionName "BootstrapIIS" `
    -VMName "WinPSDemo" `
    -Location "EastUS" `
    -Publisher Microsoft.Compute `
    -ExtensionType CustomScriptExtension `
    -TypeHandlerVersion 1.8 `
    -SettingString '{"fileUris": ["https://raw.githubusercontent.com/whelmed/la-az300/master/001_deploy_infrastructure/vms/web_bootstrap.ps1"], "commandToExecute":"powershell -ExecutionPolicy Unrestricted -File web_bootstrap.ps1"}' 

# Clean up by running
# Remove-AzureRmResourceGroup -Name YourResourceGroupNameHere