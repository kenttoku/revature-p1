#!/bin/bash

# Create VM
create () {
  # Variables
  vm_name=$1
  resource_group=$2
  location=$3
  image=$4
  size=$5
  admin_username=$6

  # Check for resource group. If resource group doesn't exist, create it
  echo "Validating resource group."
  if [ "$(az group exists --name "$resource_group")" = "false" ]; then
    echo "Resource group does not exist. Creating."
    az group create -n "$resource_group" -l "$location"
  fi

  # Checking existing VM for duplicates
  echo "Validating VM name."
  if [ -n "$(az vm list -g "$resource_group" --query [].name | grep "\"$vm_name\"")" ]; then
    echo "A VM with the name $vm_name already exists. Please use another name." 1>&2
    exit 1
  fi
  echo "VM name validated."

  # Create VM
  echo "Creating VM."
  az vm create \
    -n "$vm_name" \
    -g "$resource_group" \
    --image "$image" \
    --size "$size" \
    --admin-username "$admin_username" \
    --generate-ssh-keys \
    --custom-data ./cloud-init.txt
  echo "VM created."
}

# Main
main () {
  echo $1 $2 $3
}

main "$@"