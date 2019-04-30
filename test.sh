#!/bin/bash

command=$1

case "$command" in
  "1")
    ./create-vm.sh p2-group test-vm southcentralus UbuntuLTS Standard_B1s kent
    ;;
esac