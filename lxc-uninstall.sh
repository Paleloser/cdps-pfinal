echo "Borrando contenedores..."
lxc delete firewall --force
lxc delete loadbalancer --force
lxc delete webserver0 --force
lxc delete webserver1 --force
lxc delete webserver2 --force
lxc delete storage0 --force
lxc delete storage1 --force
lxc delete storage2 --force
lxc delete database --force

echo "Desinstalacion completada"