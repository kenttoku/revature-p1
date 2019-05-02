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
  cloud_config=$7

  validate_arg "$resource_group" "resource_group"
  validate_arg "$vm_name" "vm_name"
  validate_arg "$image" "image"
  validate_arg "$size" "size"
  validate_arg "$admin_username" "admin_username"
  validate_arg "$disk_name" "disk_name"
  validate_arg "$cloud_config" "cloud_config"

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
    --custom-data "$cloud_config"
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

  # VM names
  vm_name=${project_name}-vm
  vm0_name=${vm_name}-0
  vm1_name=${vm_name}-1
  vm2_name=${vm_name}-2
  vm3_name=${vm_name}-3

  # Disk names
  disk_name=${project_name}-disk
  disk0_name=${disk_name}-0
  disk1_name=${disk_name}-1
  disk2_name=${disk_name}-2
  disk3_name=${disk_name}-3

  snapshot_name=${project_name}-snapshot
  image_name=${project_name}-image

  # Check Resource Group
  check_resource_group "$resource_group" "$location"

  # Create Disk
  create_disk "$resource_group" "$disk0_name" "$disk_size"

  # Create VM w/Disk
  create_vm "$resource_group" "$vm0_name" "$image" "$size" "$admin_username" "$disk0_name" "./cloud-init.txt"

  # Get the Public IP of the VM createdvm
  publicIps=$(az vm show -g "$resource_group" -n "$vm0_name" -d --query publicIps | sed 's/"//g')
  echo $publicIps

  # Copy App to VM
  ssh -o "StrictHostKeyChecking=no" "${admin_username}@${publicIps}" "mkdir -p /home/${admin_username}/img-drive/client"
  scp -r img-drive/client "${admin_username}@${publicIps}:/home/${admin_username}/img-drive"
  scp -r img-drive/package.json "${admin_username}@${publicIps}:/home/${admin_username}/img-drive"
  scp -r img-drive/server.js "${admin_username}@${publicIps}:/home/${admin_username}/img-drive"

  # Wait for VM to finish cloud-init
  while [ "$(az vm show -g "$resource_group" -n "$vm0_name" -d --query powerState)" != "\"VM stopped\"" ]; do
    echo "Waiting for VM to stop"
    sleep 30
  done

  # Detach disk from VM
  echo "Detaching disk."
  az vm disk detach -g "$resource_group" -n "$disk0_name" --vm-name "$vm0_name"
  echo "Detached Disk disk."

  # Create snapshot of disk
  echo "Creating snapshot."
  az snapshot create -g "$resource_group" -n "$snapshot_name" --source "$disk0_name"
  echo "Snapshot created."

  # Deallocate VM
  echo "Deallocating VM."
  az vm deallocate -g "$resource_group" -n "$vm0_name"
  echo "Deallocated VM."

  # Generalize VM
  echo "Generalizing VM."
  az vm generalize -g "$resource_group" -n "$vm0_name"
  echo "Generalized VM."

  # Create image of VM
  echo "Creating image."
  az image create -g "$resource_group" -n "$image_name" --source "$vm0_name"
  echo "Image created."

  # Create 3 disks from snapshot
  echo "Creating disks from snapshot"
  az disk create -g "$resource_group" -n "${disk1_name}" --source "$snapshot_name"
  az disk create -g "$resource_group" -n "${disk2_name}" --source "$snapshot_name"
  az disk create -g "$resource_group" -n "${disk3_name}" --source "$snapshot_name"
  echo "Disks created from snapshot"

  # Create 3 VMs from Image
  echo "Creating VMs from image."
  create_vm "$resource_group" "${vm1_name}" "$image_name" "$size" "$admin_username" "${disk1_name}" "./start-app.txt"
  create_vm "$resource_group" "${vm2_name}" "$image_name" "$size" "$admin_username" "${disk2_name}" "./start-app.txt"
  create_vm "$resource_group" "${vm3_name}" "$image_name" "$size" "$admin_username" "${disk3_name}" "./start-app.txt"
  echo "VMs created."

  # Open Ports
  echo "Opening ports."
  az vm open-port -g "$resource_group" -n "${vm1_name}" --port 8080
  az vm open-port -g "$resource_group" -n "${vm2_name}" --port 8080
  az vm open-port -g "$resource_group" -n "${vm3_name}" --port 8080
  echo "Ports opened."

  # Show VMs
  az vm list -d --output table
  echo "Script complete"
}

main "$@"

