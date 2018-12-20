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
echo "Se apaga el contenedor."
lxc stop firewall
sleep 2

# Network config

echo "Se configura la red del contenedor"

echo "Se agrega interfaz eth1 al contenedor, que se une a la red intra-lan0"
lxc network attach intra-lan0 firewall eth1
echo "Se arranca el contenedor"
lxc start firewall
sleep 2
echo "Se configura la interfaz eth1 de manera estática"
lxc file push ./firewall/lxc-centos7-static-ip-cfg.sh firewall/root/
lxc exec firewall -- bash -c "chmod +x ./lxc-centos7-static-ip-cfg.sh"
lxc exec firewall -- bash -c "./lxc-centos7-static-ip-cfg.sh eth1 10.1.0.1"
lxc exec firewall -- bash -c "rm ./lxc-centos7-static-ip-cfg.sh"
echo "Se habilita redireccionamiento IP"
lxc exec firewall -- bash -c "echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf"
lxc exec firewall -- bash -c "systemctl restart network"
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