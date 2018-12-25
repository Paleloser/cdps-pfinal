#!/bin/bash

node="loadbalancer1"
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

echo "..Se instala haproxy"
lxc exec $node -- bash -c "apt-get install -y haproxy 1>/dev/null"
echo "...haproxy instalado"
echo "..Se instala lynx"
lxc exec $node -- bash -c "apt-get install -y lynx 1>/dev/null"
echo "...lynx instalado"
echo "..Se instala tcpdump"
lxc exec $node -- bash -c "apt-get install -y tcpdump 1>/dev/null"
echo "...tcpdump instalado"
echo "..Se instala traceroute"
lxc exec $node -- bash -c "apt-get install -y traceroute 1>/dev/null"
echo "...traceroute instalado"
echo "..Se instala nmap"
lxc exec $node -- bash -c "apt-get install -y traceroute 1>/dev/null"
echo "...traceroute nmap"

# Load balancing config
lxc file push ./scripts/haproxy.cfg $node/etc/haproxy/haproxy.cfg
lxc exec $node -- bash -c "service haproxy restart"

# Network config
  
echo ".Se configura la red del contenedor $node"

echo "..Se apaga el contenedor para establecer la configuración de red."
lxc stop $node
sleep 2
echo "..Se configuran sus interfaces eth0 y eth1"
lxc network attach intra-lan0 $node eth0
lxc network attach intra-lan1 $node eth1
echo "..Se arranca el contenedor"
lxc start $node
sleep 2

echo "..Se aplica el plan de red."
i=1
eth0="10.1.0.$(($i + 1))/24"
eth1="10.1.1.$i/24"
lxc file push ./scripts/lxc-ubuntu-static-ip-cfg.sh $node/root/
lxc exec $node -- bash -c "chmod +x /root/lxc-ubuntu-static-ip-cfg.sh"
lxc exec $node -- bash -c "/root/lxc-ubuntu-static-ip-cfg.sh $eth0 $eth1"
lxc exec $node -- bash -c "rm /root/lxc-ubuntu-static-ip-cfg.sh"
echo "..Se habilita el redireccionamiento IP"
lxc exec $node -- bash -c "echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf"

echo "[$node listo]"
