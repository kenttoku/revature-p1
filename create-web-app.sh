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

# Get blob storage account key
echo "Retrieving blob storage account key"
blob_storage_account_key=$(az storage account keys list \
  -g $resource_group \
  -n $blob_storage_account \
  --query [0].value \
  --output tsv)
echo "Blob storage account key retrieved: $blob_storage_account_key"

# Create storage container
echo "Creating storage container"
az storage container create \
  -n images \
  --account-name $blob_storage_account \
  --account-key $blob_storage_account_key \
  --public-access container
echo "Storage container created"

# Create SQL Server
echo "Creating SQL Server"
az sql server create \
  -g $resource_group \
  -n $db_server_name \
  -u $db_username \
  -l $location \
  -p $db_password
echo "SQL Server created"

# Create SQL Database
echo "Creating SQL DB"
az sql db create \
  -g $resource_group \
  -n $db_name \
  -s $db_server_name
echo "SQL DB created"

# Create App Service Plan
echo "Creating App Service Plan"
az appservice plan create \
  -g $resource_group \
  -n $plan_name \
  --sku B1 \
  --is-linux \
  --number-of-workers 3
echo "App Service Plan created"

# Create Web App
echo "Create Web App"
az webapp create \
  -g $resource_group \
  -n $app_name \
  --plan $plan_name \
  --runtime "NODE|10.14"
echo "Web App Created"

# Add Client IP to server firewall rule
echo "Adding client IP to server filewall rules"
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
echo "Firewall rules updated"

# Add environment variables to Web App
echo "Adding environment variables to web app"
az webapp config appsettings set \
  --name $app_name \
  --resource-group $resource_group \
  --settings AZURE_STORAGE_ACCOUNT_NAME=$blob_storage_account \
  AZURE_STORAGE_ACCOUNT_ACCESS_KEY=$blob_storage_account_key \
  DB_NAME=$db_name \
  DB_USERNAME=$db_username \
  DB_PASSWORD=$db_password \
  DB_HOST=${db_server_name}.database.windows.net
echo "Environment variables added"

# Deploy Web App from Github repo
echo "Deploying Web App"
az webapp deployment source config \
  -g $resource_group \
  -n $app_name \
  --repo-url $repo \
  --branch master \
  --manual-integration
echo "Web App deployed"

# Open webapp to check
az webapp browse -g $resource_group -n $app_name

echo "Script completed"
