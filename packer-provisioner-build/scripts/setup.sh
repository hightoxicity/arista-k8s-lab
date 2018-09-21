#!/bin/bash -eux

export DEBIAN_FRONTEND=noninteractive

hostnamectl set-hostname "provisioner"

apt-get install software-properties-common -y
LC_ALL=C.UTF-8  apt-add-repository ppa:ansible/ansible -y
apt-get update
apt-get install ansible -y
apt-get install python-pip -y
pip install ntc-ansible

apt-get install jq -y
pip install yq

mask2cdr ()
{
   # Assumes there's no "255." after a non-255 byte in the mask
   local x=${1##*255.}
   set -- 0^^^128^192^224^240^248^252^254^ $(( (${#1} - ${#x})*2 )) ${x%%.*}
   x=${1%%$3*}
   echo $(( $2 + (${#x}/4) ))
}

provisioner=$(cat /provisioning/group_vars/all.yml | yq -r '.provisioner')
mgmt_mask=$(cat /provisioning/group_vars/all.yml | yq -r '.mgmt_mask')
cdrmask=$(mask2cdr ${mgmt_mask})
vagrantif="eth0"
mgtif="eth1"

cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ${vagrantif}:
      dhcp4: true
    ${mgtif}:
      addresses: [ "${provisioner}/${cdrmask}" ]
EOF

/usr/sbin/netplan apply

#itf=$(ip link show | grep 'DOWN' | cut -d':' -f2
#ip address add ${provisioner}/${mgmt_mask} dev ${itf}

apt-get install policykit-1 -y

echo "Installation completed..."

cat <<'EOF' >/usr/local/bin/firstboot.sh
#!/bin/bash

mask2cdr ()
{
   # Assumes there's no "255." after a non-255 byte in the mask
   local x=${1##*255.}
   set -- 0^^^128^192^224^240^248^252^254^ $(( (${#1} - ${#x})*2 )) ${x%%.*}
   x=${1%%$3*}
   echo $(( $2 + (${#x}/4) ))
}

(
  flock -n 200 || exit 1
  if [ ! -f ~/firstboot ]; then

    read -r -d '' netplanheader << 'NPHDEOF'
network:
  version: 2
  renderer: networkd
  ethernets:
NPHDEOF

    netplanstart=''
    if [ ! -z "${VAGRANT}" ]; then
      read -r -d '' netplanstart <<'NPSTEOF'
    eth0:
      dhcp4: true
NPSTEOF
    fi

    provisioner=$(cat /provisioning/group_vars/all.yml | yq -r '.provisioner')
    mgmt_mask=$(cat /provisioning/group_vars/all.yml | yq -r '.mgmt_mask')

    mac=$(cat /provisioning/hosts | yq -r '.all.children.servers.hosts.provisioner.mac' | sed -e 's/[0-9A-F]\{2\}/&:/g' -e 's/:$//'| tr '[:upper:]' '[:lower:]')
    cdrmask=$(mask2cdr ${mgmt_mask})

    read -r -d '' netplanmgt <<NPMGEOF
    mgmtif:
      match:
        macaddress: "${mac}"
      addresses: [ "${provisioner}/${cdrmask}" ]
NPMGEOF

    netcfg=$(mktemp)
    echo -e "${netplanheader}" > ${netcfg}
    if [ ! -z "${netplanstart}" ]; then
      echo -e "    ${netplanstart}" >> ${netcfg}
    fi
    echo -e "    ${netplanmgt}" >> ${netcfg}
    sudo echo "ENABLED=1" | sudo tee -a /etc/default/netplan
    sudo mv ${netcfg} /etc/netplan/01-netcfg.yaml
    sudo /usr/sbin/netplan apply

    sudo parted /dev/sda resizepart 1 100%
    sudo pvresize /dev/sda1
    sudo lvextend -l +100%FREE /dev/mapper/trunk--vg-root
    sudo resize2fs /dev/mapper/trunk--vg-root

    cd /provisioning
    ansible-playbook ./provisioner.yml

    [ $? -eq 0 ] && touch ~/firstboot || exit 1
  fi
) 200>/var/lock/firstboot.lock
EOF

chmod 755 /usr/local/bin/firstboot.sh

SVC_ENV=""

cat <<EOF >/etc/systemd/system/firstboot.service;
[Unit]
Description=first boot
Wants=network-online.target
After=network-online.target
StartLimitInterval=200
StartLimitBurst=5

[Service]
Environment=${SVC_ENV}
Type=simple
ExecStart=/usr/local/bin/firstboot.sh
RestartSec=10
Restart=on-failure
StandardOutput=journal
User=vagrant
Group=vagrant

[Install]
#WantedBy=multi-user.target
WantedBy=sysinit.target
EOF

systemctl daemon-reload
systemctl enable firstboot

# TODO: implement in ansible (provisioner playbook)
/provisioning/provisioner-config/setup.sh

mv /home/vagrant/k8snode-raw /var/www/html/k8snode-raw
cd /var/www/html/
bzip2 k8snode-raw

#su -p - vagrant -c "/usr/local/bin/firstboot.sh"
#rm -rf /home/vagrant/firstboot

su - vagrant -c "cd /provisioning && ansible-playbook ./provisioner.yml"
