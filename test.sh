#!/bin/bash

command=$1

case "$command" in
  "start")
    ./create-vm.sh "$2" test-vm southcentralus UbuntuLTS Standard_B1s kent
    ;;
  "deletegroup")
    az group delete --no-wait -yg "$2"
    ;;
  "vmtable")
    az vm list -d --output table
    ;;
esac