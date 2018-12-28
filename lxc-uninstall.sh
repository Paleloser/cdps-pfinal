user=$(whoami)
if [ $user != 'root' ]; then
  echo "El programa ha de ejecutarse como root"
  exit
fi

echo "Borrando contenedores..."
lxc delete nagios1 --force
lxc delete firewall1 --force
lxc delete loadbalancer1 --force
lxc delete webserver1 --force
lxc delete webserver2 --force
lxc delete webserver3 --force
lxc delete storage1 --force
lxc delete storage2 --force
lxc delete storage3 --force
lxc delete database1 --force

echo "Desconectando interfaces de red"
sudo ifconfig intra-lan0 down
sudo ifconfig intra-lan1 down
sudo ifconfig intra-lan2 down
sudo ifconfig intra-mgmt down

echo "Borrando bridges"
sudo brctl delbr intra-lan0
sudo brctl delbr intra-lan1
sudo brctl delbr intra-lan2
sudo brctl delbr intra-mgmt

echo "Borrando ficheros intermedios"
rm ./scripts/lxc-py-*
rm interfaces

echo "Desinstalacion completada"