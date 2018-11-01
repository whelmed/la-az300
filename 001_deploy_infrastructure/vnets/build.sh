#!/bin/bash

# Fail on errors
set -e

RESOURCE_GROUP="NetworkingGroup"
REGION="eastus"
VNET_NAME="web-application-network"
WEB_NSG="web-nsg"

# Subnets
DMZ_SUBNET="dmz-subnet"
WEB_SUBNET="web-subnet"
NVA_SUBNET="nva-subnet"

# Grab the password for the VMs. This assumes both use the same password. Which is fine for this demo.
read -s -p "Type the VM Password: " VM_PASSWORD

az group create --name $RESOURCE_GROUP --location $REGION

# Create a virtual network with a dmz subnet.
az network vnet create \
  --name              $VNET_NAME \
  --resource-group    $RESOURCE_GROUP \
  --location          $REGION \
  --address-prefix    10.0.0.0/16 \
  --subnet-name       $DMZ_SUBNET \
  --subnet-prefix     10.0.0.0/24

# Create a web subnet.
az network vnet subnet create \
  --address-prefix    10.0.1.0/24 \
  --name              $WEB_SUBNET \
  --resource-group    $RESOURCE_GROUP \
  --vnet-name         $VNET_NAME

# Create a nva subnet.
az network vnet subnet create \
  --address-prefix    10.0.2.0/24 \
  --name              $NVA_SUBNET \
  --resource-group    $RESOURCE_GROUP \
  --vnet-name         $VNET_NAME

# Create a network security group for the web & nva subnet.
az network nsg create \
  --resource-group    $RESOURCE_GROUP \
  --name              $WEB_NSG \
  --location          $REGION


az network vnet subnet update \
  --vnet-name               $VNET_NAME \
  --name                    $WEB_SUBNET \
  --resource-group          $RESOURCE_GROUP \
  --network-security-group  $WEB_NSG


# Create a NIC for the web server VM.
az network nic create \
  --resource-group          $RESOURCE_GROUP \
  --name                    web-nic \
  --vnet-name               $VNET_NAME \
  --subnet                  $WEB_SUBNET \
  --network-security-group  $WEB_NSG 

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


# Create a NIC for the NVA VM.
az network nic create \
  --resource-group          $RESOURCE_GROUP \
  --name                    nva-nic \
  --vnet-name               $VNET_NAME \
  --subnet                  $NVA_SUBNET \
  --ip-forwarding           true \
  --network-security-group  $WEB_NSG  

# Dump a bash script for the nva server to /tmp
# This will enable port forwarding in a persistent way
cat > /tmp/nva.txt << EOL
#cloud-config
runcmd:
  - cat /etc/sysctl.conf | sed 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' | sudo tee /etc/sysctl.conf 
  - sudo sysctl -p /etc/sysctl.conf
EOL

# Create a NVA VM in the NVA subnet.
az vm create \
  --resource-group        $RESOURCE_GROUP \
  --authentication-type   password \
  --name                  nva \
  --nics                  nva-nic   \
  --image                 Canonical:UbuntuServer:18.04-LTS:latest \
  --admin-username        bobross \
  --admin-password        $VM_PASSWORD \
  --custom-data           /tmp/nva.txt


# Fetch the private IP of the web server
WEB_PRIVATE_IP=$(az vm list-ip-addresses -g $RESOURCE_GROUP -n web1 --query "[0].virtualMachine.network.privateIpAddresses[0]" | sed 's/"//g')

# Create a new Application Gateway
az network application-gateway create \
    -g                                      $RESOURCE_GROUP \
    -n                                      web-gateway \
    --capacity                              2 \
    --sku                                   WAF_Medium \
    --vnet-name                             $VNET_NAME \
    --subnet                                $DMZ_SUBNET \
    --http-settings-cookie-based-affinity   Enabled \
    --public-ip-address                     AppGatewayPublicIp \
    --servers                               $WEB_PRIVATE_IP



# Create the routes that will direct traffic from the web app through the NVA
az network route-table create -g $RESOURCE_GROUP -n web-subnet-routes
az network route-table create -g $RESOURCE_GROUP -n dmz-subnet-routes

# Grab the IP of the NVA
NVA_PRIVATE_IP=$(az network nic show -g $RESOURCE_GROUP -n nva-nic --query "ipConfigurations[0].privateIpAddress" | sed 's/"//g')

# Route traffic heading from the web server to the nva
az network route-table route create \
    -g                      $RESOURCE_GROUP \
    --route-table-name      web-subnet-routes \
    -n                      WebToGatewayViaNVA \
    --next-hop-type         VirtualAppliance \
    --address-prefix        10.0.0.0/24 \
    --next-hop-ip-address   $NVA_PRIVATE_IP

# Route traffic heading from the gateway to the web server to the nva
az network route-table route create \
    -g                      $RESOURCE_GROUP \
    --route-table-name      dmz-subnet-routes \
    -n                      GatewayToWebViaNVA \
    --next-hop-type         VirtualAppliance \
    --address-prefix        10.0.1.0/24 \
    --next-hop-ip-address   $NVA_PRIVATE_IP

# Add the route table to the web subnet
az network vnet subnet update \
  --vnet-name         $VNET_NAME \
  --name              $WEB_SUBNET  \
  --resource-group    $RESOURCE_GROUP \
  --route-table       web-subnet-routes

# Add the route table to the nva subnet
az network vnet subnet update \
  --vnet-name       $VNET_NAME \
  --name            $DMZ_SUBNET  \
  --resource-group  $RESOURCE_GROUP \
  --route-table     dmz-subnet-routes


# Phase 2
# Create a new group for the network to peer with
DEV_RESOURCE_GROUP="Development$RESOURCE_GROUP"
DEV_VNET_NAME="dev-$VNET_NAME"

az group create --name $DEV_RESOURCE_GROUP --location $REGION

# Ensure the IP address range is non-overlapping with the web network
az network vnet create \
  --name              $DEV_VNET_NAME \
  --resource-group    $DEV_RESOURCE_GROUP \
  --location          $REGION \
  --address-prefix    10.1.0.0/16 \
  --subnet-name       default \
  --subnet-prefix     10.1.0.0/24


# Install the web server, and change the landing page to distinguish it from the other website
cat > /tmp/dev.txt << EOL
#cloud-config
package_upgrade: true
packages:
  - apache2
runcmd:
  - echo "Development Server" | sudo tee /var/www/html/index.html
EOL

# Create a Public IP address (PIP)
az network public-ip create -g $DEV_RESOURCE_GROUP -n dev-server-pip

# Create the nic with a pip
az network nic create \
  --resource-group      $DEV_RESOURCE_GROUP \
  --name                dev-nic \
  --vnet-name           $DEV_VNET_NAME \
  --subnet              default \
  --public-ip-address   dev-server-pip

# Create a Dev VM in the default subnet, in the dev vnet
az vm create \
  --resource-group        $DEV_RESOURCE_GROUP \
  --authentication-type   password \
  --name                  dev-web \
  --nics                  dev-nic   \
  --image                 Canonical:UbuntuServer:18.04-LTS:latest \
  --admin-username        bobross \
  --admin-password        $VM_PASSWORD \
  --custom-data           /tmp/dev.txt


WEB_VNET_ID=$(az network vnet show -g $RESOURCE_GROUP -n $VNET_NAME -o tsv --query id)
# Peer the two networks
az network vnet peering create \
  -g                  $DEV_RESOURCE_GROUP \
  -n                  DevToWebPeering \
  --vnet-name         $DEV_VNET_NAME \
  --remote-vnet       $WEB_VNET_ID \
  --allow-vnet-access


DEV_VNET_ID=$(az network vnet show -g $DEV_RESOURCE_GROUP -n $DEV_VNET_NAME -o tsv --query id)
az network vnet peering create \
  -g                  $RESOURCE_GROUP \
  -n                  WebToDevPeering \
  --vnet-name         $VNET_NAME \
  --remote-vnet       $DEV_VNET_ID \
  --allow-vnet-access