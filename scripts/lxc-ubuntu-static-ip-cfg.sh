#!/bin/bash

file="/etc/netplan/10-lxc.yaml"
touch $file

echo "network:" > $file
echo "  version: 2" >> $file
echo "  ethernets:" >> $file
echo "    eth0:" >> $file
echo "      dhcp4: no" >> $file
echo "      addresses:" >> $file
echo "        - $1" >> $file
if [ -n $2 ]; then
  echo "    eth1:" >> $file
  echo "      dhcp4: no" >> $file
  echo "      addresses:" >> $file
  echo "        - $2" >> $file
fi

netplan apply
