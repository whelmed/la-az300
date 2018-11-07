#!/bin/bash

# Fail on errors
set -e

RESOURCE_GROUP="VMGroup"
REGION="eastus"
VNET_NAME="vm-demo-network"
NSG="vm-demo-nsg"
SUBNET="default"
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


# Create a NIC for the web server VM.
az network nic create \
  --resource-group          $RESOURCE_GROUP \
  --name                    vm-demo-nic \
  --vnet-name               $VNET_NAME \
  --subnet                  $SUBNET \
  --network-security-group  $NSG 

# Dump a bash script for the web server to /tmp
cat > /tmp/web.txt << EOL
#cloud-config
package_upgrade: true
packages:
  - apache2
EOL

# Create a Web Server VM in the front-end subnet.
az vm create \
  --resource-group        $RESOURCE_GROUP \
  --authentication-type   password \
  --name                  web1 \
  --nics                  web-nic  \
  --image                 Canonical:UbuntuServer:18.04-LTS:latest \
  --admin-username        bobross \
  --admin-password        $VM_PASSWORD \
  --custom-data           /tmp/web.txt