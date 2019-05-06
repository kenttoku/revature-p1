#!/bin/bash
resource_group=$1
app_name=$2
location=southcentralus
db_server_name=${app_name}dbserver
db_username=sqladmin
db_password=Password12345

# Create Resource Group
echo "Creating resource group."
az group create -n $resource_group --location $location
echo "Resource group created."

# Create postgres server
echo "Creating postgres server"
az postgres server create \
  -g $resource_group \
  -n $db_server_name \
  --location $location \
  --admin-user $db_username \
  --admin-password $db_password \
  --sku-name B_Gen5_1 \
  --version 9.6
echo "Postgres server created"

# Add Own IP to server firewall rule
echo "Adding own IP to firewall rule"
my_ip=$(dig +short myip.opendns.com @resolver1.opendns.com)
az postgres server firewall-rule create \
  -g $resource_group \
  -s $db_server_name \
  -n my_ip \
  --start-ip-address $my_ip \
  --end-ip-address $my_ip
echo "Own IP added to firewall rule"

# Seed Database
echo "Seeding database"
psql "dbname=postgres host=${db_server_name}.postgres.database.azure.com user=${db_username}@${db_server_name} password=${db_password} port=5432" -f create-db.sql
psql "dbname=plxobay host=${db_server_name}.postgres.database.azure.com user=${db_username}@${db_server_name} password=${db_password} port=5432" -f plx.sql
echo "Database seeded"

echo "Script completed"

#psql "dbname=plxobay host=testdbdbserver.postgres.database.azure.com user=sqladmin@$testdbdbserver password=Password12345 port=5432"
