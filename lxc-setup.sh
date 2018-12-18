#!/bin/bash
echo "Se ejecuta el fichero ./firewall/lxc-firewall.sh que crea y configura el contenedor firewall"
chmod +x firewall/lxc-firewall.sh
./firewall/lxc-firewall.sh

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
