#!/bin/bash -eux

export DEBIAN_FRONTEND=noninteractive

hostnamectl set-hostname "k8snode"

apt-get install software-properties-common -y
apt-get update

vagrantif="eth0"

cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ${vagrantif}:
      dhcp4: true
EOF

/usr/sbin/netplan apply

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

    sudo cat << 'DHCPHKEOF' | sudo tee -a /etc/dhcp/dhclient-exit-hooks.d/vars
if [ -n "${new_vagrant+set}" ]; then
  echo "======================  dhclient exit-hooks ======================="
  echo "Custom vars filtering"
  dhcp_vars=/etc/profile.d/dhcp_vars.sh
  echo "" | sudo tee ${dhcp_vars}
  for e in `env`; do
    if echo "$e" | grep -e '^new_.*'; then
      echo "export $e" | sudo tee -a ${dhcp_vars}
    fi
  done
  echo "=================== done dhclient exit-hooks ======================="
fi
DHCPHKEOF

    netcfg=$(mktemp)

    cat << 'NPHDEOF' > ${netcfg}
network:
  version: 2
  renderer: networkd
  ethernets:
NPHDEOF
    nbitf=0
    for itf in $(ip -br link | cut -d' ' -f1 | grep 'eth'); do
      cat << ITFEOF >> ${netcfg}
    ${itf}:
      dhcp4: true
ITFEOF
      nbitf=$((nbitf+1))
    done

    sudo echo "ENABLED=1" | sudo tee -a /etc/default/netplan
    sudo mv ${netcfg} /etc/netplan/01-netcfg.yaml

    if [ "${nbitf}" -eq "3" ]; then
      sudo dhclient eth1
    else
      sudo dhclient eth0
    fi

    sudo /usr/sbin/netplan apply

    while [ ! -f /etc/profile.d/dhcp_vars.sh ]; do
      sleep 1s
    done

    . /etc/profile.d/dhcp_vars.sh

    nodeitf="eth1"

    if [ "$(ip -br link | grep 'eth2' | wc -l)" == "1" ]; then
      nodeitf="eth2"
    fi

    nodemask=$(mask2cdr ${new_nodemask})

    cat << NODEIPEOF | sudo tee -a /etc/netplan/02-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ${nodeitf}:
      addresses: [ "${new_nodeip}/${nodemask}" ]
NODEIPEOF

    sudo /usr/sbin/netplan apply

    sudo parted /dev/sda resizepart 1 100%
    sudo pvresize /dev/sda1
    sudo lvextend -l +100%FREE /dev/mapper/trunk--vg-root
    sudo resize2fs /dev/mapper/trunk--vg-root

    [ $? -eq 0 ] && touch ~/firstboot || exit 1
  fi
) 200>/var/lock/firstboot.lock
EOF

chmod 755 /usr/local/bin/firstboot.sh

mv /home/vagrant/dhclient.conf /etc/dhcp/dhclient.conf
chmod 0644 /etc/dhcp/dhclient.conf

cat <<EOF >/etc/systemd/system/firstboot.service;
[Unit]
Description=first boot
Wants=network-online.target
After=network-online.target
StartLimitInterval=200
StartLimitBurst=5

[Service]
Environment=
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

if [ "${PACKER_BUILDER_TYPE}" == "qemu" ]; then
  sed -i '/^#GRUB_DISABLE_LINUX_UUID=true/s/^#//' /etc/default/grub
  grub-install --boot-directory=/boot/ --modules="biosdisk part_msdos" /dev/vda
fi
