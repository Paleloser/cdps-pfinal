#!/bin/bash

for i in 1 2 3
do
  node="webserver$i"

  echo "[$node]"

  # Launch

  echo "Imagen: Ubuntu 18.04"

  lxc launch images:ubuntu/18.04 $node
  echo "Se esperan 5s a que el contenedor arranque"
  sleep 5
  echo "Se actualizan los paquetes del OS"
  lxc exec $node -- bash -c "apt update"
  lxc exec $node -- bash -c "apt -y upgrade"

  # Install dependencies

  echo "Se instalan las dependencias en el contenedor"

  echo "Se instala npm (y node)"
  lxc exec $node -- bash -c "apt install -y npm"
  echo "Se instala git"
  lxc exec $node -- bash -c "apt install -y git"
  echo "Se instala python"
  lxc exec $node -- bash -c "apt install -y python"
  lxc stop $node
  sleep 2

  # Install quiz platform + set env variables

  echo "Se instala el servicio web Quiz"

  # Network config
  
  echo "Se configura la red del contenedor $node"
  
  echo "Se configuran sus interfaces eth0 y eth1"
  lxc network attach intra-lan0 $node eth0
  lxc network attach intra-lan1 $node eth1
  echo "Se arranca el contenedor"
  lxc start $node
  sleep 2
  echo "Se aplica el plan de red."
  eth0="10.1.1.$(($i + 1))/24"
  eth1="10.1.2.$i/24"
  lxc file push ./webapp/lxc-apply-netplan.sh $node/root/
  lxc exec $node -- bash -c "chmod +x ./webapp/lxc-ubuntu-static-ip-cfg.sh"
  lxc exec $node -- bash -c "./webapp/lxc-ubuntu-static-ip-cfg.sh $container $eth0 $eth1"
  lxc exec $node -- bash -c "rm ./webapp/lxc-ubuntu-static-ip-cfg.sh"

  echo "[$node listo]"
done