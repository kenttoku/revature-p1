#!/bin/bash

command=$1

case "$command" in
  "start")
    ./create-vm.sh "$2" project southcentralus UbuntuLTS Standard_B1s kent
    ;;
  "deletegroup")
    if [ -n "$2" ]; then az group delete --no-wait -yg "$2"; fi
    if [ -n "$3" ]; then az group delete --no-wait -yg "$3"; fi
    if [ -n "$4" ]; then az group delete --no-wait -yg "$4"; fi
    if [ -n "$5" ]; then az group delete --no-wait -yg "$5"; fi
    ;;
  "vmtable")
    az vm list -d --output table
    ;;
esac