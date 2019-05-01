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

# Check for resource group. If resource group doesn't exist, create it
check_resource_group () {
  resource_group=$1
  location=$2

  validate_arg "$resource_group" "resource_group"
  validate_arg "$location" "location"

  echo "Validating resource group."
  if [ "$(az group exists --name "$resource_group")" = "false" ]; then
    echo "Resource group does not exist. Creating."
    az group create -n "$resource_group" -l "$location"
  fi
  echo "Resource group validated."
}

# Create Disk
create_disk () {
  resource_group=$1
  disk_name=$2
  disk_size=$3

  validate_arg "$resource_group" "resource_group"å
  validate_arg "$vm_name" "vm_name"
  validate_arg "$disk_size" "disk_size"

  echo "Creating Disk"
  az disk create -n "$disk_name" -g "$resource_group" --os-type Linux --size "$disk_size"
  echo "Disk Created"
}

# Create VM
create_vm () {
  # Variables
  resource_group=$1
  vm_name=$2
  image=$3
  size=$4
  admin_username=$5
  disk_name=$6

  validate_arg "$resource_group" "resource_group"
  validate_arg "$vm_name" "vm_name"
  validate_arg "$image" "image"
  validate_arg "$size" "size"
  validate_arg "$admin_username" "admin_username"
  validate_arg "$disk_name" "disk_name"

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
    --attach-data-disk "$disk_name" \
    --generate-ssh-keys \
    --custom-data ./cloud-init.txt
  echo "VM created."
}

# Main
main () {
  # Variables
  resource_group=$1
  project_name=$2
  location=$3
  image=$4
  size=$5
  admin_username=$6
  disk_size=10
  vm_name=${project_name}-vm
  disk_name=${project_name}-disk
  snapshot_name=${project_name}-snapshot
  image_name=${project_name}-image

  # Check Resource Group
  check_resource_group "$resource_group" "$location"

  # Create Disk
  create_disk "$resource_group" "$disk_name" "$disk_size"

  # Create VM w/Disk
  create_vm "$resource_group" "$vm_name" "$image" "$size" "$admin_username" "$disk_name"

  # Get the Public IP of the VM createdvm
  publicIps=$(az vm show -g "$resource_group" -n "$vm_name" -d --query publicIps | sed 's/"//g')
  echo $publicIps

  # Copy App to VM
  ssh -o "StrictHostKeyChecking=no" "${admin_username}@${publicIps}" "mkdir -p /home/${admin_username}/img-drive/client"
  scp -r img-drive/client "${admin_username}@${publicIps}:/home/${admin_username}/img-drive/client"
  scp -r img-drive/package.json "${admin_username}@${publicIps}:/home/${admin_username}/img-drive"
  scp -r img-drive/server.js "${admin_username}@${publicIps}:/home/${admin_username}/img-drive"

  # Wait for VM to finish cloud-init
  while [ "$(az vm show -g $resource_group -n $vm_name -d --query powerState)" != "\"VM stopped\"" ]; do
    echo "Waiting for VM to stop"
    sleep 30
  done

  echo "Detaching disk."
  az vm disk detach -g $resource_group -n $disk_name --vm-name $vm_name
  echo "Detached Disk disk."

  # Create snapshot of disk
  echo "Creating snapshot."
  az snapshot create -g $resource_group -n $snapshot_name --source $disk_name
  echo "Created snapshot."

  # Create image of VM

  # Create 3 disks from snapshot

  # Create 3 VMs from Image
}

main "$@"

