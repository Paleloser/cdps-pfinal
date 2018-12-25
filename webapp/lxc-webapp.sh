#!/bin/bash

for i in 1 2 3
do
  node="webserver$i"

  echo "[$node]"

  # Launch

  echo ".Imagen: Ubuntu 18.04"

  lxc launch images:ubuntu/18.04 $node 1>/dev/null
  echo "..Contenedor creado"
  echo ".Se esperan 5s a que el contenedor arranque"
  sleep 5
  echo ".Se actualizan los paquetes del OS"
  lxc exec $node -- bash -c "apt-get update 1>/dev/null"
  echo "..Repositorios actualizados"
  lxc exec $node -- bash -c "apt-get -y upgrade 1>/dev/null"
  echo "..Programas actualizados"

  # Install dependencies

  echo ".Se instalan las dependencias en el contenedor"

  echo "..Se instala npm/node"
  lxc exec $node -- bash -c "apt-get install -y npm 1>/dev/null"
  echo "...npm/node instalado"
  echo "..Se instala git"
  lxc exec $node -- bash -c "apt-get install -y git 1>/dev/null"
  echo "...git instalado"

  # Install quiz platform + set env variables
  echo ".Se instala el servicio web Quiz"
  lxc file push ./scripts/lxc-webapp-setup-quiz.sh $node/root/
  lxc exec $node -- bash -c "chmod +x lxc-webapp-setup-quiz.sh"
  lxc exec $node -- bash -c "./lxc-webapp-setup-quiz.sh"
  if [ $i = 1 ]; then
    echo "..Se migran los datos de la BBDD"
    lxc exec $node -- bash -c "cd quiz_2019 && npm run-script migrate_cdps 1>/dev/null"
    lxc exec $node -- bash -c "cd quiz_2019 && npm run-script seed_cdps 1>/dev/null"
  fi
  lxc exec $node -- bash -c "rm lxc-webapp-setup-quiz.sh"
  echo "..Se configura el arranque del servicio al bootear"
  lxc file push ./scripts/lxc-webapp-start-on-boot.sh $node/etc/init.d/
  lxc exec $node -- bash -c "chown root /etc/init.d/lxc-webapp-start-on-boot.sh"
  lxc exec $node -- bash -c "chgrp root /etc/init.d/lxc-webapp-start-on-boot.sh"
  lxc exec $node -- bash -c "chmod 755 /etc/init.d/lxc-webapp-start-on-boot.sh"
  lxc exec $node -- bash -c "sudo update-rc.d lxc-webapp-start-on-boot.sh defaults"
  echo "..Servicio quiz configurado."

  # Network config
  
  echo ".Se configura la red del contenedor $node"

  echo "..Se apaga el contenedor para establecer la configuración de red."
  lxc stop $node
  sleep 2
  echo "..Se configuran sus interfaces eth0 y eth1"
  lxc network attach intra-lan1 $node eth0
  lxc network attach intra-lan2 $node eth1
  echo "..Se arranca el contenedor"
  lxc start $node
  sleep 2

  echo ".Se aplica el plan de red."
  eth0="10.1.1.$(($i + 1))/24"
  eth1="10.1.2.$i/24"
  lxc file push ./scripts/lxc-ubuntu-static-ip-cfg.sh $node/root/
  lxc exec $node -- bash -c "chmod +x /root/lxc-ubuntu-static-ip-cfg.sh"
  lxc exec $node -- bash -c "/root/lxc-ubuntu-static-ip-cfg.sh $eth0 $eth1"
  echo "..Direcciones estáticas asignadas"
  lxc exec $node -- bash -c "rm /root/lxc-ubuntu-static-ip-cfg.sh"
  # lxc exec $node -- bash -c "ip route add default via 10.1.1.$(($i + 1))"
  lxc restart $node
  echo "[$node listo]"
done