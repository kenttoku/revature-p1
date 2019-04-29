#!/bin/bash

# Validate Arguments
validate_arg () {
  arg=$1
  arg_name=$2

  if [ -z "$arg" ]; then
    echo "Missing argument '$arg_name'." 1>&2
    exit 1
  fi
}

# Create VM
create_vm () {
  # Variables
  vm_name=$1
  resource_group=$2
  location=$3
  image=$4
  size=$5
  admin_username=$6

  validate_arg "$vm_name" "vm_name"
  validate_arg "$resource_group" "resource_group"
  validate_arg "$location" "location"
  validate_arg "$image" "image"
  validate_arg "$size" "size"
  validate_arg "$admin_username" "admin_username"

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
  create_vm "$@"
}

main "$@"