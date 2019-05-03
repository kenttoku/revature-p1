#!/bin/bash

command=$1

case "$command" in
  "start")
    ./create-web-app.sh "$2" img-drive "imgdrive${3}" git@github.com:kenttoku/img-drive.git
    ;;
  "deletegroup")
    if [ -n "$2" ]; then az group delete -yg "$2"; fi
    if [ -n "$3" ]; then az group delete -yg "$3"; fi
    if [ -n "$4" ]; then az group delete -yg "$4"; fi
    if [ -n "$5" ]; then az group delete -yg "$5"; fi
    ;;
  "vmtable")
    az vm list -d --output table
    ;;
esac