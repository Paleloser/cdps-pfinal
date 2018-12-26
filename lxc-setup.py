import json
import sys
import os
import time
import yaml

# Minor functions

def parseAddr(addr, i):
  split1=addr.split('/')
  split2=[]
  for j in range(0, len(split1)):
    split2.append(split1[j].split('.'))
  # we get something like [[AA, AA, AA, AA], [MM]]
  # we want to set pos [0][3]
  split2[0][3]=int(split2[0][3])+i
  res=('%s.%s.%s.%s/%s' % (split2[0][0], split2[0][1], split2[0][2], split2[0][3], split2[1][0]))
  return res

# Core functions

def launchContainer(node, cfg):
  os.system('lxc launch %s %s 1>/dev/null' % (cfg['image'], node))
  time.sleep(5)

def updateContainer(node, cfg):
  print('[%s]..Se actualizan los paquetes' % (node))
  os.system('lxc exec %s -- bash -c "apt-get update 1>/dev/null"' % (node))
  os.system('lxc exec %s -- bash -c "apt-get upgrade 1>/dev/null"' % (node))

def installDependencies(node, cfg):
  print('[%s]..Se instalan las dependencias' % (node))
  for dep in cfg['dependencies']:
    print('[%s]...Se instala %s' % (node, dep))
    os.system('lxc exec %s -- bash -c "apt-get install -y %s 1>/dev/null"' % (node, dep))
  print('[%s]..Dependencias instaladas' % (node))

def configNetwork(node, cfg):
  print('[%s]..Se configuran las interfaces de red' % (node))
  print('[%s]..Se para el contenedor' % (node))
  os.system('lxc stop %s 1>/dev/null' % (node))
  for interface in cfg['interfaces']:
    if interface['network'] == 'default':
      continue
    else:
      print('[%s]...Se anade la red %s a la interfaz %s' % (node, interface['network'], interface['name']))
      os.system('lxc network attach %s %s %s' % (interface['network'], node, interface['name']))
  print('[%s]..Se inicia el contenedor' % (node))
  os.system('lxc start %s 1>/dev/null' % (node))

def createNetplan(node, cfg, i):
  print('[%s]..Se crea el plan de red' % (node))
  netplan={}
  netplan['network']={
    "version": 2,
    "ethernets": {}
  }
  for interface in cfg['interfaces']:
    print('[%s]...Se configura %s' % (node, interface['name']))
    if interface['network'] == 'default':
      netplan['network']['ethernets'][str(interface['name'])]={
        "dhcp4": True
      }
    else:
      addr=parseAddr(interface['address'], i)
      netplan['network']['ethernets'][str(interface['name'])]={
        "dhcp4": 'no',
        "addresses": [str(addr)]
      }
      if 'gateway4' in interface:
        netplan['network']['ethernets'][str(interface['name'])]['gateway4']=str(interface['gateway4'])
  print("[%s]....Plan: %s" % (node, netplan))
  with open('10-lxc.yaml', 'w') as outfile:
    yaml.dump(netplan, outfile, default_flow_style=False, allow_unicode=False)
  outfile.close()

def applyNetplan(node, cfg):
  print('[%s]..Se aplica el plan de red' % (node))
  os.system('lxc file push ./10-lxc.yaml %s/etc/netplan/10-lxc.yaml' % (node))
  os.system('lxc exec %s -- bash -c "netplan apply"' % (node))
  if 'forwarding' in cfg:
    if cfg['forwarding']:
      print('[%s]...Se habilita redireccionamiento IP' % (node))
      os.system('lxc exec %s -- bash -c \"echo \'net.ipv4.ip_forward = 1\' >> /etc/sysctl.conf\"' % (node))

def setEnv(node, cfg):
  print('[%s]..Se configuran las variables de entorno' % (node))
  for var in cfg['env']:
    print('[%s]...Se anade: %s=%s' % (node, var, cfg['env'][var]))
    os.system('lxc exec %s -- bash -c \"export %s=%s\"' % (node, var, cfg['env'][var]))
    os.system('lxc exec %s -- bash -c \"echo \'export %s=%s\' >> /root/.bashrc\"' % (node, var, cfg['env'][var]))

def run(node, cfg):
  print('[%s]..Se ejecuta la pila de run definidos' % (node))
  for script in cfg['run']:
    print('[%s]...Se ejecuta: %s' % (node, script))
    os.system('lxc exec %s -- bash -c "%s"' % (node, script))

def cmd(node, cfg):
  print('[%s]..Se genera el script a correr on-boot' % (node))
  bootfile=open('./scripts/lxc-on-boot.sh', 'r+')
  if os.path.exists('./scripts/lxc-py-%s-on-boot.sh' % (node)):
    os.remove('./scripts/lxc-py-%s-on-boot.sh' % (node))
  outfile=open('./scripts/lxc-py-%s-on-boot.sh' % (node), 'w+')
  for script in cfg['cmd']:
    print('[%s]...Se anade: %s' % (node, script))
    for line in bootfile:
      if 'start)' in line:
        outfile.write(line)
        outfile.write('%s' % (script))
      else:
        outfile.write(line)
  bootfile.close()
  outfile.close()
  print('[%s]...Se sube el script a %s/etc/init.d/' % (node, node))
  os.system('lxc file push scripts/lxc-py-%s-on-boot.sh %s/etc/init.d/lxc-%s-on-boot.sh' % (node, node, node))
  os.system('lxc exec %s -- bash -c "chmod 755 /etc/init.d/lxc-%s-on-boot.sh"' % (node, node))
  os.system('lxc exec %s -- bash -c "chown root /etc/init.d/lxc-%s-on-boot.sh"' % (node, node))
  os.system('lxc exec %s -- bash -c "chgrp root /etc/init.d/lxc-%s-on-boot.sh"' % (node, node))
  os.system('lxc exec %s -- bash -c "sudo update-rc.d lxc-%s-on-boot.sh defaults"' % (node, node))

def runScripts(cfg):
  print('[******]..Se ejecuta la pila de scripts literales definidos')
  for script in cfg['scripts']:
    print('[******]...Se ejecuta: %s' % (script))
    os.system('%s' % (script))
  
def createSingleContainer(cfg, i):
  node="%s%s" % (cfg['name'], i+1)
  print('[%s].Se crea el contenedor' % (node))
  launchContainer(node, cfg)
  print('[%s].Se configura el contenedor' % (node))
  updateContainer(node, cfg)
  installDependencies(node, cfg)
  if 'env' in cfg:
    setEnv(node, cfg)
  if 'run' in cfg:
    run(node, cfg)
  if 'cmd' in cfg:
    cmd(node, cfg)
  # networking stuff should be applied at last instance
  configNetwork(node, cfg)
  createNetplan(node, cfg, i)
  applyNetplan(node, cfg)

def createReplicatedContainer(cfg, replicas):
  for i in range(0, replicas):
    createSingleContainer(cfg, i)

def createContainer(cfg):
  if cfg['replication']:
    replicas=cfg['replication']
    createReplicatedContainer(cfg, replicas)
  else:
    createSingleContainer(cfg, 0)
  # this is only executed once, wether if replication is enabled or not
  if 'scripts' in cfg:
    runScripts(cfg)

def switch(x):
  if (x == 'firewall'):
    createContainer(cfg)
  if (x == 'loadbalancer'):
    createContainer(cfg)
  if (x == 'webserver'):
    createContainer(cfg)

filename=sys.argv[1]
fopen=open(filename, 'r')
cfg=json.load(fopen)

switch(cfg['name'])