#!/bin/bash
resource_group=$1
plan_name=$2
app_name=$3
repo=$4
location=southcentralus
blobStorageAccount=${3}blob

# Create Resource Group
az group create -n $resource_group --location $location

# Create Blob Storage Account
az storage account create --name $blobStorageAccount \
  --location $location --resource-group $resource_group \
  --sku Standard_LRS --kind blobstorage --access-tier hot

blobStorageAccountKey=$(az storage account keys list -g $resource_group \
  -n $blobStorageAccount --query [0].value --output tsv)

az storage container create -n images --account-name $blobStorageAccount \
--account-key $blobStorageAccountKey --public-access off

az storage container create -n thumbnails --account-name $blobStorageAccount \
--account-key $blobStorageAccountKey --public-access container

echo "Make a note of your Blob storage account key..."
echo $blobStorageAccountKey

az appservice plan create -g $resource_group -n $plan_name --sku B1
az webapp create -g $resource_group -n $app_name --plan $plan_name --runtime "node|10.6"

az webapp config appsettings set --name $app_name --resource-group $resource_group \
  --settings AZURE_STORAGE_ACCOUNT_NAME=$blobStorageAccount \
  AZURE_STORAGE_ACCOUNT_ACCESS_KEY=$blobStorageAccountKey

az webapp deployment source config -g $resource_group -n $app_name \
  --repo-url $repo --branch master --manual-integration

az appservice plan update -g $resource_group -n $plan_name --number-of-workers 3

az webapp browse -g $resource_group -n $app_name