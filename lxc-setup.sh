#!/bin/bash

# intra-lan0: internal - 10.1.0.0/24 - firewall + lb
# intra-lan1: internal - 10.1.1.0/24 - lb + webapp
# intra-lan2: internal - 10.1.2.0/24 - webapp + database + storage
#  mgmt-lan0: work - 10.2.0.0/24 - [OPTIONAL] nagios + mgmt + else 

user=$(whoami)
if [ $user != 'root' ]; then
  echo "El programa ha de ejecutarse como root"
  exit
fi

# dependencies check

echo ".Se hace un control de dependencias"

ntools=$(dpkg-query -W -f='${Status}' net-tools 2>/dev/null | grep -c "ok installed")
if [ $ntools = 0 ]; then
  echo "..Se instalan las net-tools para poder manejar las interfaces de red"
  sudo apt install -y net-tools
fi;
echo "..net-tools ya instalado"

bctl=$(dpkg-query -W -f='${Status}' bridge-utils 2>/dev/null | grep -c "ok installed")
if [ $bctl = 0 ]; then
  echo "..Se instala bridge-utils para poder levantar bridges virtuales"
  sudo apt install -y bridge-utils
fi
echo "..bridge-utils ya instalado"

# net config

echo ".Se procede a configurar el entorno de red"

echo "..Se crea bridge que aisla la red interna de la publica"
sudo brctl addbr intra-lan0
echo "..Se crea bridge que aisla la red de los servicios de la del balanceador"
sudo brctl addbr intra-lan1
echo "..Se crea bridge que aisla la red de almacenamiento de la de los servidores"
sudo brctl addbr intra-lan2
echo "..Se procede a levantar los bridges en el sistema"
sudo ifconfig intra-lan0 up
sudo ifconfig intra-lan1 up
sudo ifconfig intra-lan2 up

# lxc

chmod +x ./firewall/lxc-firewall.sh
./firewall/lxc-firewall.sh
# chmod +x ./loadbalancer/lxc-loadbalancer.sh
# ./loadbalancer/lxc-loadbalancer.sh
# chmod +x ./webapp/lxc-webapp.sh
# ./webapp/lxc-webapp.sh

# echo "Para poder configurar glusterfs los contenedores han de tener privilegios sobre el sistema"
# echo "Se procede a escalar de privilegios a los contenedores storage"
# lxc config set storage0 security.privileged true
# lxc config set storage1 security.privileged true
# lxc config set storage2 security.privileged true
# echo "Se procede a configurar glusterfs"
# # GLUSTERFS CONFIG HERE
# echo "Para evitar fallas en la seguridad deshacemos los privilegios anteriores sobre storage"
# lxc config set storage0 security.privileged false
# lxc config set storage1 security.privileged false
# lxc config set storage2 security.privileged false
