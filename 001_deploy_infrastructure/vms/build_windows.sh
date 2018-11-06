#!/bin/bash

# Fail on errors
set -e

RESOURCE_GROUP="VMGroup"
REGION="eastus"
VNET_NAME="vm-win-demo-network"
NSG="vm-win-demo-nsg"
SUBNET="default"
VM_NAME="demo-vm"
# Grab the password for the VM
read -s -p "Type the VM Password: " VM_PASSWORD

az group create --name $RESOURCE_GROUP --location $REGION

# Create a virtual network with a default subnet.
az network vnet create \
  --name              $VNET_NAME \
  --resource-group    $RESOURCE_GROUP \
  --location          $REGION \
  --address-prefix    10.0.0.0/16 \
  --subnet-name       $SUBNET \
  --subnet-prefix     10.0.0.0/24


# Create a network security group for the default subnet.
az network nsg create \
  --resource-group    $RESOURCE_GROUP \
  --name              $NSG \
  --location          $REGION


az network vnet subnet update \
  --vnet-name               $VNET_NAME \
  --name                    $SUBNET \
  --resource-group          $RESOURCE_GROUP \
  --network-security-group  $NSG


# Create the public IP
az network public-ip create -g $RESOURCE_GROUP -n demo-windows-ip
# Create a NIC for the web server VM.
az network nic create \
  --resource-group          $RESOURCE_GROUP \
  --name                    vm-demo-nic \
  --vnet-name               $VNET_NAME \
  --subnet                  $SUBNET \
  --network-security-group  $NSG \
  --public-ip-address       demo-windows-ip


# Create a Web Server VM in the front-end subnet.
az vm create \
  --resource-group        $RESOURCE_GROUP \
  --authentication-type   password \
  --name                  $VM_NAME \
  --nics                  vm-demo-nic \
  --image                 win2016datacenter \
  --admin-username        bobross \
  --admin-password        $VM_PASSWORD 


az vm extension set \
  --resource-group $RESOURCE_GROUP \
  --vm-name $VM_NAME \
  --name CustomScriptExtension \
  --publisher Microsoft.Compute \
  --settings '{"fileUris": ["https://raw.githubusercontent.com/whelmed/la-az300/master/001_deploy_infrastructure/vms/web_bootstrap.ps1"], "commandToExecute":"powershell -ExecutionPolicy Unrestricted -File web_bootstrap.ps1"}' \

