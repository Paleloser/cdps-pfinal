#!/bin/bash

while getopts ":i:g:a:n:" opt
do
    case $opt in
        i ) 
          v1=$OPTARG
        ;;
        a ) 
          v2=$OPTARG
        ;;
        g ) 
          v3=$OPTARG
        ;;
        n ) 
          v4=$OPTARG
        ;;
        \? ) echo "Opcion invalida -$OPTARG"
          exit 1 ;;
        : ) echo "Opcion -$OPTARG requiere un argumento"
          exit 1 ;;
    esac
done

if [ -z $v1 ] || [ -z $v2 ]; then
  echo "Uso: ./lxc-centos7-static-ip-cfg.sh -i <interfaz> -a <dirección> [-g <gateway>][-n <netmask>]"
  echo "Ejemplo: ./lxc-centos7-static-ip-cfg.sh -i eth1 -a 10.1.0.2 -g 10.1.0.1 -n 255.255.0.0"
  exit 1
fi

# Script

file="/etc/sysconfig/network-scripts/ifcfg-$v1"
touch $file

echo "DEVICE=$v1" > $file
echo "BOOTPROTO=static" >> $file
echo "IPADDR=$v2" >> $file
if [ -n $v3 ]; then
  echo "GATEWAY=$v3" >> $file
fi
if [ -n $v4 ]; then
  echo "NETMASK=$v4" >> $file
elif [ -z $v4]; then
  echo "No se proporciona máscara de subred, se asume /24" 
  echo "NETMASK=255.255.255.0" >> $file
fi