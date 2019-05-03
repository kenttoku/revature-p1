#!/bin/bash
resource_group=$1
plan_name=$2
app_name=$3
repo=$4
location=southcentralus
blobStorageAccount=kentblobtest123


az group create -n $resource_group --location $location
az appservice plan create -g $resource_group -n $plan_name --sku B1
az webapp create -g $resource_group -n $app_name --plan $plan_name --runtime "node|6.9"
az webapp browse -g $resource_group -n $app_name
az webapp deployment source config -g $resource_group -n $app_name \
  --repo-url $repo --branch master --manual-integration
az appservice plan update -g $resource_group -n $plan_name --number-of-workers 3

az storage account create --name $blobStorageAccount \
  --location $location --resource-group $resource_group \
  --sku Standard_LRS --kind blobstorage --access-tier hot


# az storage account create --name kentblobtest123 \
#   --location southcentralus --resource-group p4 \
#   --sku Standard_LRS --kind blobstorage --access-tier hot