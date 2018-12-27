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

echo "[******].Se hace un control de dependencias"

ntools=$(dpkg-query -W -f='${Status}' net-tools 2>/dev/null | grep -c "ok installed")
if [ $ntools = 0 ]; then
  echo "[******]..Se instalan las net-tools para poder manejar las interfaces de red"
  sudo apt install -y net-tools
fi;
echo "[******]..net-tools ya instalado"

bctl=$(dpkg-query -W -f='${Status}' bridge-utils 2>/dev/null | grep -c "ok installed")
if [ $bctl = 0 ]; then
  echo "[******]..Se instala bridge-utils para poder levantar bridges virtuales"
  sudo apt install -y bridge-utils
fi
echo "[******]..bridge-utils ya instalado"

# python pakcages check

echo "[******].Se hace un control de paquetes python"

if python -c 'import pkgutil; exit(not pkgutil.find_loader("pybrctl"))'; then
    echo '[******]..Paquete de python pybrctl ya instalado'
else
    echo '[******]..Se instala el paquete de python: pybrctl'
    pip install pybrctl
fi

if python -c 'import pkgutil; exit(not pkgutil.find_loader("yaml"))'; then
    echo '[******]..Paquete de python yaml ya instalado'
else
    echo '[******]..Se instala el paquete de python: yaml'
    pip install yaml
fi

python ./lxc-setup.py ./firewall/firewall-cfg.json
python ./lxc-setup.py ./loadbalancer/loadbalancer-cfg.json
python ./lxc-setup.py ./database/database-cfg.json
python ./lxc-setup.py ./storage/storage-cfg.json
python ./lxc-setup.py ./webapp/webserver-cfg.json