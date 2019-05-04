#!/bin/bash

command=$1

case "$command" in
  "start")
    ./create-web-app.sh "$2" img-drive "imgdrive${3}" "git@github.com:kenttoku/img-drive.git"
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
  "firewall")
    my_ip=$(dig +short myip.opendns.com @resolver1.opendns.com)
    az postgres server firewall-rule create \
      -g test-group \
      -s imgdrivekent123dbserver \
      -n my_ip \
      --start-ip-address $my_ip \
      --end-ip-address $my_ip
    echo $my_ip
    ;;
esac