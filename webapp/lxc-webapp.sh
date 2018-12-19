#!/bin/bash

for i in 3
do
  node="webapp$i"

  echo "[$node]"

  # Launch

  echo "Imagen: Ubuntu 18.04"

  lxc launch images:ubuntu/18.04 $node
  echo "Se esperan 2s a que el contenedor arranque"
  echo "Se actualizan los paquetes del OS"
  lxc exec $node -- bash -c "apt update"
  lxc exec $node -- bash -c "apt -y upgrade"

  # Install dependencies

  echo "Se instalan las dependencias en el contenedor"

  echo "Se instala npm (y node)"
  lxc exec $node -- bash -c "apt install -y npm"
  echo "Se instala git"
  lxc exec $node -- bash -c "apt install -y git"

  # Install quiz platform + set env variables

  # Network config
  
  echo "Se configura la red del contenedor $node"
  
  lxc network attach intra-lan0 $node eth0
  lxc network attach intra-lan1 $node eth1
  echo "Se aplica el plan de red."
  eth0="10.1.1.$(($i + 1))/24"
  eth1="10.1.2.$i/24"
  python lxc-apply-netplan.py $container $eth0 $eth1

  echo "[$node listo]"
done