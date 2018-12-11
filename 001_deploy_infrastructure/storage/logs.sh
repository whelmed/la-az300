#!/bin/bash
# Fail on errors
set -e

STORAGE_ACCOUNT_NAME='blueshiftla'
STORAGE_ACCOUNT_KEY=''

# Grab the key.
read -s -p "Paste the Storage Account Key: " $STORAGE_ACCOUNT_KEY

# List the names of the logs
az storage blob list \
    -c '$logs' \
    --account-key '' \
    --account-name $STORAGE_ACCOUNT_NAME \
    --output 'json' \
    --query "[].name"


# Download logs
azcopy \
    --source "https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/\$logs/blob" \
    --destination . \
    --source-key $STORAGE_ACCOUNT_KEY \
    --recursive