file="/etc/sysconfig/network-scripts/ifcfg-$1"
touch $file
echo "DEVICE=$1" > $file
echo "BOOTPROTO=static" >> $file
echo "IPADDR=$2" >> $file
echo "NETMASK=255.255.255.0" >> $file