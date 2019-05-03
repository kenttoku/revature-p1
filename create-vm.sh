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
  if [ "$(az group exists -n "$resource_group")" = "false" ]; then
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
  availability_set=$8

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

# Create VM
create_vmas () {
  # Variables
  resource_group=$1
  vm_name=$2
  image=$3
  size=$4
  admin_username=$5
  disk_name=$6
  cloud_config=$7
  availability_set=$8
  nic=$9

  validate_arg "$resource_group" "resource_group"
  validate_arg "$vm_name" "vm_name"
  validate_arg "$image" "image"
  validate_arg "$size" "size"
  validate_arg "$admin_username" "admin_username"
  validate_arg "$disk_name" "disk_name"
  validate_arg "$cloud_config" "cloud_config"
  validate_arg "$availability_set" "availability_set"

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
    --custom-data "$cloud_config" \
    --availability-set "$availability_set" \
    --nics "$nic" \
    --no-wait
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
  admin_username=kent
  disk_size=10

  # VM names
  vm_name=${project_name}-vm
  vm_original_name=${vm_name}-original
  vm_as_name=${vm_name}-as

  # Disk names
  disk_name=${project_name}-disk
  disk_original_name=${disk_name}-original
  disk_as_name=${disk_name}-as

  # Other names
  snapshot_name=${project_name}-snapshot
  custom_image=${project_name}-image
  as_name=${project_name}-as
  public_ip_name=${project_name}-ip
  load_balancer_name=${project_name}-lb
  load_balancer_rule_name=${project_name}-lbr
  front_end_ip_name=${project_name}-fip
  back_end_pool_name=${project_name}-bep
  health_probe_name=${project_name}-hp
  vnet_name=${project_name}-vnet
  subnet_name=${project_name}-subnet
  nsg_name=${project_name}-ngs
  nic_name=${project_name}-nic


  # Check Resource Group
  check_resource_group "$resource_group" "$location"

  # Create Disk
  create_disk "$resource_group" "$disk_original_name" "$disk_size"

  # Create VM w/Disk
  create_vm "$resource_group" "$vm_original_name" "$image" "$size" "$admin_username" "$disk_original_name" "./cloud-init.txt"

  # Get the Public IP of the VM createdvm
  publicIps=$(az vm show -g "$resource_group" -n "$vm_original_name" -d --query publicIps | sed 's/"//g')
  echo $publicIps

  # Copy App to VM
  ssh -o "StrictHostKeyChecking=no" "${admin_username}@${publicIps}" "mkdir -p /home/${admin_username}/img-drive/client"
  scp -r img-drive/client "${admin_username}@${publicIps}:/home/${admin_username}/img-drive"
  scp -r img-drive/server "${admin_username}@${publicIps}:/home/${admin_username}/img-drive"
  scp -r img-drive/package.json "${admin_username}@${publicIps}:/home/${admin_username}/img-drive"

  # Wait for VM to finish cloud-init
  while [ "$(az vm show -g "$resource_group" -n "$vm_original_name" -d --query powerState)" != "\"VM stopped\"" ]; do
    echo "Waiting for VM to stop"
    sleep 30
  done

  # Detach disk from VM
  echo "Detaching disk."
  az vm disk detach -g "$resource_group" -n "$disk_original_name" --vm-name "$vm_original_name"
  echo "Detached Disk disk."

  # Create snapshot of disk
  echo "Creating snapshot."
  az snapshot create -g "$resource_group" -n "$snapshot_name" --source "$disk_original_name"
  echo "Snapshot created."

  # Deallocate VM
  echo "Deallocating VM."
  az vm deallocate -g "$resource_group" -n "$vm_original_name"
  echo "Deallocated VM."

  # Generalize VM
  echo "Generalizing VM."
  az vm generalize -g "$resource_group" -n "$vm_original_name"
  echo "Generalized VM."

  # Create image of VM
  echo "Creating image."
  az image create -g "$resource_group" -n "$custom_image" --source "$vm_original_name"
  echo "Image created."

  # Create 3 disks from snapshot
  echo "Creating disks from snapshot."
  az disk create -g "$resource_group" -n "${disk_as_name}1" --source "$snapshot_name"
  az disk create -g "$resource_group" -n "${disk_as_name}2" --source "$snapshot_name"
  az disk create -g "$resource_group" -n "${disk_as_name}3" --source "$snapshot_name"
  echo "Disks created from snapshot."

  # Setting Up Load Balancer
  echo "Creating Load Balancer."
  az network public-ip create \
     -g "$resource_group" \
     -n "$public_ip_name"

  az network lb create \
    -g "$resource_group" \
    -n "$load_balancer_name" \
    --frontend-ip-name "$front_end_ip_name" \
    --backend-pool-name "$back_end_pool_name" \
    --public-ip-address "$public_ip_name"

  az network lb probe create \
    -g "$resource_group" \
    --lb-name "$load_balancer_name" \
    -n "$health_probe_name" \
    --protocol tcp \
    --port 80

  az network lb rule create \
    -g "$resource_group" \
    --lb-name "$load_balancer_name" \
    -n "$load_balancer_rule_name" \
    --protocol tcp \
    --frontend-port 80 \
    --backend-port 80 \
    --frontend-ip-name "$front_end_ip_name" \
    --backend-pool-name "$back_end_pool_name" \
    --probe-name "$health_probe_name"
  echo "Load Balancer Created."

  # Create Network Resources
  az network vnet create \
    -g "$resource_group" \
    -n "$vnet_name" \
    --subnet-name "$subnet_name"

  az network nsg create \
    -g "$resource_group" \
    -n "$nsg_name"

  az network nsg rule create \
    -g "$resource_group" \
    --nsg-name "$nsg_name" \
    -n "$nsg_name"Rule \
    --priority 1001 \
    --protocol tcp \
    --destination-port-range 80

  for i in `seq 1 3`; do
    az network nic create \
      -g "$resource_group" \
      -n "${nic_name}${i}" \
      --vnet-name "$vnet_name" \
      --subnet "$subnet_name" \
      --network-security-group "$nsg_name" \
      --lb-name "$load_balancer_name" \
      --lb-address-pools "$back_end_pool_name"
  done

  # Create an Availability Set
  echo "Creating VM Availability Set."
  az vm availability-set create \
    -g "$resource_group" \
    -n "$as_name" \
    --platform-fault-domain-count 3 \
    --platform-update-domain-count 3
  echo "VM Availability Set Created."

  # # Create 3 VMs from Image
  echo "Creating VMs in Availability Set."
  create_vmas "$resource_group" "${vm_as_name}1" "$custom_image" "$size" "$admin_username" "${disk_as_name}1" "./start-app.txt" "$as_name" "${nic_name}1"
  create_vmas "$resource_group" "${vm_as_name}2" "$custom_image" "$size" "$admin_username" "${disk_as_name}2" "./start-app.txt" "$as_name" "${nic_name}2"
  create_vmas "$resource_group" "${vm_as_name}3" "$custom_image" "$size" "$admin_username" "${disk_as_name}3" "./start-app.txt" "$as_name" "${nic_name}3"
  echo "VMs created."

  # Show VMs
  az vm list -d --output table
  echo "Script complete"
}

main "$@"

