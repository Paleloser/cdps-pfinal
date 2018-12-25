#!/bin/bash

node="firewall1"
echo "[$node]"

# Launch

echo ".Imagen: CentOS7"

lxc launch images:centos/7 $node 1>/dev/null
echo "..Contenedor creado"
echo ".Se esperan 10s a que el contenedor arranque"
sleep 10
echo ".Se actualizan los paquetes del OS"
lxc exec $node -- bash -c "yum update 1>/dev/null"
echo "..Repositorios actualizados"
lxc exec $node -- bash -c "yum -y upgrade 1>/dev/null"
echo "..Programas actualizados"

# Install dependencies

echo ".Se instalan las dependencias en el contenedor"

echo "..Se instala lynx para control de servicio"
lxc exec $node -- bash -c "yum install -y lynx 1>/dev/null"
echo "...lynx instalado"
echo "..Se instalan las net-tools para poder usar ifconfig"
lxc exec $node -- bash -c "yum install -y net-tools 1>/dev/null"
echo "... net-tools instalado"
echo "..Se instala tcpdump para control de paquetes"
lxc exec $node -- bash -c "yum install -y tcpdump 1>/dev/null"
echo "...tcpdump instalado"
echo "..Se instala traceroute para control de paquetes"
lxc exec $node -- bash -c "yum install -y traceroute 1>/dev/null"
echo "...traceroute instalado"
echo "..Se instala la herramienta nmap para admin. de red"
lxc exec $node -- bash -c "yum install -y nmap 1>/dev/null"
echo "...nmap instalado"
echo "..Se instala la herramienta firewalld para admin. del firewall"
lxc exec $node -- bash -c "yum install -y firewalld 1>/dev/null"
echo "...firewalld instalado"
lxc exec $node -- bash -c "systemctl enable firewalld"

# Network config

echo ".Se configura la red del contenedor"

echo "..Se apaga el contenedor para establecer la configuración de red."
lxc stop $node
sleep 2
echo "..Se agrega interfaz eth1 al contenedor, que se une a la red intra-lan0"
lxc network attach intra-lan0 $node eth1
echo "..Se arranca el contenedor"
lxc start $node
sleep 2

echo "..Se configura la interfaz eth1 de manera estática"
lxc file push ./scripts/lxc-centos7-static-ip-cfg.sh firewall/root/
lxc exec $node -- bash -c "chmod +x ./lxc-centos7-static-ip-cfg.sh"
lxc exec $node -- bash -c "./lxc-centos7-static-ip-cfg.sh -i eth1 -a 10.1.0.1 -g 10.1.0.2 -n 255.255.0.0"
lxc exec $node -- bash -c "rm ./lxc-centos7-static-ip-cfg.sh"
echo "..Se habilita redireccionamiento IP"
lxc exec $node -- bash -c "echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf"
lxc exec $node -- bash -c "systemctl restart network"
echo "..Red configurada"

# Firewall config

echo ".Se configura el firewall"

lxc exec $node -- bash -c "firewall-cmd --permanent --zone=public --add-interface=eth0 1>/dev/null"
lxc exec $node -- bash -c "firewall-cmd --permanent --zone=public --add-service=http 1>/dev/null"
lxc exec $node -- bash -c "firewall-cmd --permanent --zone=public --add-service=https 1>/dev/null"
lxc exec $node -- bash -c "firewall-cmd --permanent --zone=public --add-rich-rule 'rule family=ipv4 forward-port port=80 protocol=tcp to-port=80 to-addr=10.1.0.2' 1>/dev/null"
lxc exec $node -- bash -c "firewall-cmd --permanent --zone=public --add-rich-rule 'rule family=ipv4 forward-port port=443 protocol=tcp to-port=443 to-addr=10.1.0.2' 1>/dev/null"
lxc exec $node -- bash -c "firewall-cmd --permanent --zone=internal --change-interface=eth1 1>/dev/null"
lxc exec $node -- bash -c "firewall-cmd --permanent --zone=internal --add-rich-rule='rule protocol value='icmp' accept' 1>/dev/null"
echo "..Se aplican las reglas configuradas"
lxc exec $node -- bash -c "systemctl restart firewalld"
lxc exec $node -- bash -c "firewall-cmd --permanent --zone=public --list-all"
lxc exec $node -- bash -c "firewall-cmd --permanent --zone=internal --list-all"
echo "..Firewall configurado"

echo "[$node listo]"