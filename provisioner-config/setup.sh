#!/bin/bash

# NGINX webserver
apt-get install -y nginx-extras

cat << 'EOF' > /var/www/html/boot.ipxe
#!ipxe
set base-url http://10.0.5.254
kernel ${base-url}/coreos_production_pxe.vmlinuz cloud-config-url=${base-url}/cloud-config.yml
initrd ${base-url}/coreos_production_pxe_image.cpio.gz
boot
EOF

cat << 'EOF' > /var/www/html/cloud-config.yml
#cloud-config
users:
  - name: "vagrant"
    passwd: "$6$rounds=4096$4S.G09ZHPcYZC$JhFqOqReRHrjzWBUNoCacC36/sCBdzQuLDuW5KsmY2QYDgim20DY4VgQOMOhVumQpygCVG24QHBYREQSIJGKz1"
    groups:
      - "sudo"
write_files:
  - path: "/firstboot.sh"
    permissions: "0755"
    owner: "root"
    content: |
      #!/bin/bash
      sudo dd conv=nocreat count=1024 if=/dev/zero of=/dev/sda \
        seek=$(($(sudo blockdev --getsz /dev/sda) - 1024)) status=none
      curltry=0
      for curltry in 0 1 2 4; do
        sleep "$curltry"
        curl http://10.0.5.254/k8snode-raw.bz2 | bzip2 -cd | sudo dd bs=1M conv=nocreat of=/dev/sda status=none && unset curltry && break ||
        echo "Failed to curl and dd image to /dev/sda"
      done
      [ -z "$curltry" ] || exit 1
      sudo udevadm settle
      try=0
      for try in 0 1 2 4; do
        sleep "$try"
        sudo blockdev --rereadpt /dev/sda && unset try && break ||
        echo "Failed to reread partitions on /dev/sda" >&2
      done
      [ -z "$try" ] || exit 1
      sudo udevadm settle
      sudo reboot
coreos:
  units:
    - name: "firstboot.service"
      command: "start"
      content: |
        [Unit]
        Description=first boot
        Wants=network-online.target
        After=network-online.target
        StartLimitInterval=200
        StartLimitBurst=5

        [Service]
        Environment=
        Type=simple
        ExecStart=/firstboot.sh
        RestartSec=10
        Restart=on-failure
        StandardOutput=journal
        User=vagrant
        Group=vagrant

        [Install]
        WantedBy=sysinit.target
EOF

cat << 'EOF' > /etc/nginx/sites-available/default
server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/html;
        server_name _;
        location / {
                try_files $uri $uri/ =404;
        }
}
EOF

cd /var/www/html
wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz
wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz

systemctl restart nginx

### TFTPD configuration
apt-get install -y tftpd-hpa
cp /provisioning/provisioner-config/ressources/tftpd-hpa /etc/default/tftpd-hpa
mkdir /tftpboot
cp /provisioning/provisioner-config/ressources/undionly.kpxe /tftpboot
systemctl restart tftpd-hpa

### PXE configuration
apt-get install -y ipxe
