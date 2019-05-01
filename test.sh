#!/bin/bash

command=$1

case "$command" in
  "start")
    ./create-vm.sh "$2" project southcentralus UbuntuLTS Standard_B1s kent
    ;;
  "deletegroup")
    az group delete --no-wait -yg "$2"
    az group delete --no-wait -yg "$3"
    az group delete --no-wait -yg "$4"
    az group delete --no-wait -yg "$5"
    ;;
  "vmtable")
    az vm list -d --output table
    ;;
esac