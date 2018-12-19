#!/bin/bash

echo "[firewall]"

# Launch

echo "Imagen: CentOS7"

lxc launch images:centos/7 firewall
echo "Se esperan 10s a que el contenedor arranque"
sleep 10
echo "Se actualizan los paquetes del OS"
lxc exec firewall -- bash -c "yum update"
lxc exec firewall -- bash -c "yum -y upgrade"

# Install dependencies

echo "Se instalan las dependencias en el contenedor"

echo "Se instalan las net-tools para poder usar ifconfig"
lxc exec firewall -- bash -c "yum install -y net-tools"
echo "Se instala tcpdump para control de paquetes"
lxc exec firewall -- bash -c "yum install -y tcpdump"
echo "Se instala la herramienta firewalld para admin. del firewall"
lxc exec firewall -- bash -c "yum install -y firewalld"
lxc exec firewall -- bash -c "systemctl enable firewalld"
# If other dependencies are needed put them right here
echo "Se reinicia el contenedor, esperando 5s para que arranque"
lxc exec firewall -- bash -c "reboot"
sleep 5

# Network config

echo "Se configura la red del contenedor"

echo "Se agrega interfaz eth1 al contenedor, que se une a la red intra-lan0"
lxc network attach intra-lan0 firewall eth1
echo "Se configura la interfaz eth1 de manera estática"
lxc exec firewall -- bash -c "ifconfig eth1 10.1.0.1/24" # NOTE: this should be done on /etc/sysconfig/network-scripts/ifcfg-eth1
echo "Se habilita redireccionamiento IP"
lxc exec firewall -- bash -c "echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf"
echo "Red configurada"

# Firewall config

echo "Se configura el firewall"

lxc exec firewall -- bash -c "firewall-cmd --permanent --zone=public --add-interface=eth0"
lxc exec firewall -- bash -c "firewall-cmd --permanent --zone=internal --add-interface=eth1"
echo "Se habilita el servicio http por la red lan0"
lxc exec firewall -- bash -c "firewall-cmd --zone=public --permanent --add-service=http"
echo "Se habilita el servicio http por la red intra-lan0"
lxc exec firewall -- bash -c "firewall-cmd --zone=internal --permanent --add-service=http"
echo "Firewall configurado"

# Interesa generar un keypair para control por ssh => instalar openssh-server y configurar

# End of configs. Reboot and done.

echo "[firewall listo]"