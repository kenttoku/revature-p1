#!/bin/bash
resource_group=$1
plan_name=$2
app_name=$3
repo=$4
location=southcentralus
blob_storage_account=${app_name}blob
db_server_name=${app_name}dbserver
db_name=${app_name}db
db_username=sqladmin
db_password=Password12345

# Create Resource Group
echo "Creating resource group."
az group create -n $resource_group --location $location
echo "Resource group created."

# Create Blob Storage Account
echo "Creating blob storage account"
az storage account create \
  --name $blob_storage_account \
  --location $location \
  --resource-group $resource_group \
  --sku Standard_LRS \
  --kind blobstorage \
  --access-tier hot
echo "Blob storage account created"

blob_storage_account_key=$(az storage account keys list \
  -g $resource_group \
  -n $blob_storage_account \
  --query [0].value \
  --output tsv)

echo "Creating storage container"
az storage container create \
  -n images \
  --account-name $blob_storage_account \
  --account-key $blob_storage_account_key \
  --public-access container
echo "Storage container created"

echo "Make a note of your Blob storage account key..."
echo $blob_storage_account_key

az sql server create -g $resource_group -n $db_server_name -u $db_username -l $location -p $db_password
az sql db create -g $resource_group -n $db_name -s $db_server_name

az appservice plan create -g $resource_group -n $plan_name --sku B1 --is-linux --number-of-workers 3
az webapp create -g $resource_group -n $app_name --plan $plan_name --runtime "NODE|10.14"

client_ip_list=$(az webapp show -g $resource_group -n $app_name  --query "outboundIpAddresses" -o tsv)

for client_ip in $(echo $client_ip_list | sed "s/,/ /g")
do
  az sql server firewall-rule create \
    -g $resource_group \
    -s $db_server_name \
    -n $client_ip \
    --start-ip-address $client_ip \
    --end-ip-address $client_ip
done

az webapp config appsettings set --name $app_name --resource-group $resource_group \
  --settings AZURE_STORAGE_ACCOUNT_NAME=$blob_storage_account \
  AZURE_STORAGE_ACCOUNT_ACCESS_KEY=$blob_storage_account_key \
  DB_NAME=$db_name \
  DB_USERNAME=$db_username \
  DB_PASSWORD=$db_password \
  DB_HOST=${db_server_name}.database.windows.net

az webapp deployment source config -g $resource_group -n $app_name \
  --repo-url $repo --branch master --manual-integration

az webapp browse -g $resource_group -n $app_name

