# -*- mode: ruby -*-
# vi: set ft=ruby :

# Specify minimum Vagrant version and Vagrant API version
Vagrant.require_version ">= 2.1.4"

# Plugins we require
required_plugins = %w(vagrant-vbguest vagrant-host-shell vagrant-reload)

##### START Helper functions
def install_ssh_key()
  puts "Adding ssh key to the ssh agent"
  puts "ssh-add #{Vagrant.source_root}/keys/vagrant"
  system "ssh-add #{Vagrant.source_root}/keys/vagrant"
end

def custom_has_plugin?(name, version=nil)
  return false unless Vagrant.plugins_enabled?

  if !version
    # We check the plugin names first because those are cheaper to check
    return true if Vagrant.plugin("2").manager.registered.any? { |p| p.name == name }
  end

  # Make the requirement object
  version = Gem::Requirement.new([version]) if version

  # Now check the plugin gem names
  require "vagrant/plugin/manager"
  Vagrant::Plugin::Manager.instance.installed_plugins.any? do |s|
    match = s[0] == name
    next match if !version
    next match && version.satisfied_by?(s.version)
  end
end

def install_plugins(required_plugins)
  if Vagrant.plugins_enabled?
    plugins_to_install = required_plugins.select { |plugin| not custom_has_plugin?(plugin)}

    if not plugins_to_install.empty?
      puts "Installing plugins: #{plugins_to_install.join(' ')}"
      if system "vagrant plugin install #{plugins_to_install.join(' ')}"
        exec "vagrant #{ARGV.join(' ')}"
      else
        abort "Installation of one or more plugins has failed. Aborting."
      end
    end
  end
end
##### END Helper functions

# Install ssh key
#
# Uncomment the next line if you're using ssh-agent
# install_ssh_key

# Check certain plugins are installed
install_plugins required_plugins

# Require YAML module
require 'yaml'

# Read YAML file with box details
vagrant_root = File.dirname(__FILE__)
hosts = YAML.load_file(vagrant_root + '/topology.yml')

# Lab definition begins here
Vagrant.configure("2") do |config|

  config.vm.provider "libvirt"
  config.vm.provider "virtualbox"

  config.vm.boot_timeout = 1200

  config.vbguest.auto_update = false

  config.vm.define "output-router-01" do |rt|
    config.ssh.insert_key = true
    rt.vm.base_mac = "16189D18A689"
    rt.vm.box = "ubuntu/bionic64"
    rt.vm.synced_folder '.', '/vagrant', id: "vagrant-root", disabled: true

    rt.vm.network "private_network", auto_config: false, type: "static", virtualbox__intnet: "O1L1", mac: "16189D18A68C", ip: "169.254.1.11", libvirt__network_name: "O1L1", libvirt__forward_mode: "veryisolated", libvirt__dhcp_enabled: false, libvirt__mtu: 1500, model_type: "e1000"

    script = <<-'SCRIPT'
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/01-router.conf
sysctl -p
sed -ie 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0 \1"/g' /etc/default/grub
update-grub
ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules

cat <<'EOF' > /etc/systemd/network/01-eth0.link
[Match]
MACAddress=16:18:9d:18:a6:89

[Link]
Name=eth0
MacAddressPolicy=persistent
NamePolicy=mac
EOF

cat <<'EOF' > /etc/systemd/network/01-eth1.link
[Match]
MACAddress=16:18:9d:18:a6:8c

[Link]
Name=eth1
MacAddressPolicy=persistent
NamePolicy=mac
EOF

cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    net1:
      dhcp4: true
      match:
        macaddress: "16:18:9d:18:a6:89"
      set-name: "eth0"
    net2:
      match:
        macaddress: "16:18:9d:18:a6:8c"
      set-name: "eth1"
  vlans:
    vlan45:
      id: 45
      link: net2
      addresses: [ "172.16.64.1/24" ]
      routes:
        - to: 10.0.5.0/24
          via: 172.16.64.254
EOF

rm -rf /etc/netplan/50-cloud-init.yaml

/usr/sbin/netplan apply

SCRIPT

    scriptPostReboot = <<-'SCRIPT'
iptables -t nat -A POSTROUTING -s 172.16.64.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.0.5.0/24 -o eth0 -j MASQUERADE
iptables-save -c > /etc/iptables.rules

apt-get install -y networkd-dispatcher

cat << 'EOF' > /etc/network/if-up.d/iptables
#! /bin/sh
set -e

/sbin/iptables-restore < /etc/iptables.rules
EOF

chmod +x /etc/network/if-up.d/iptables

cat << 'EOF' >  /usr/lib/networkd-dispatcher/routable.d/50-ifup-hooks
#!/bin/sh

for d in up post-up; do
    hookdir=/etc/network/if-${d}.d
    [ -e $hookdir ] && /bin/run-parts $hookdir
done
exit 0
EOF

cat << 'EOF' >  /usr/lib/networkd-dispatcher/routable.d/50-ifdown-hooks
#!/bin/sh

for d in down post-down; do
    hookdir=/etc/network/if-${d}.d
    [ -e $hookdir ] && /bin/run-parts $hookdir
done
exit 0
EOF

chmod +x /usr/lib/networkd-dispatcher/routable.d/50-ifup-hooks
chmod +x /usr/lib/networkd-dispatcher/routable.d/50-ifdown-hooks

SCRIPT

    rt.vm.provision "shell" do |s|
      s.privileged = true
      s.inline = script
    end

    rt.vm.provision :reload

    rt.vm.provision "shell" do |s|
      s.privileged = true
      s.inline = scriptPostReboot
    end

  end

  # Iterate through entries in YAML file
  hosts.each do |host|

    config.vm.define host["name"] do |srv|

      script = ""

      config.ssh.insert_key = false

      args = Array.new
      args.push(host["name"])

      srv.vm.provider :libvirt do |libvirt, override|

        override.vm.box = host["box"]["libvirtbox"]
        override.vm.box_version = host["box"]["libvirtbox_version"]

        if /provisioner/.match(host['name'])
          override.vm.synced_folder '.', '/vagrant', id: "vagrant-root", disabled: true
          override.vm.synced_folder '.', '/provisioning', type: 'rsync',
            rsync__exclude: [ ".gitignore", ".git/", "./misc", "packer-k8snode-build", "packer-provisioner-build", "packer-trunk-build", "packer-veoslibvirt-build", ".vagrant", "*.qcow2", "*.vmdk", "*.box" ]
        else
          if /(?i:veos)/.match(host['box']['vbox'])
            override.vm.synced_folder '.', '/vagrant', id: "vagrant-root", disabled: true
            libvirt.disk_bus = 'ide'
            libvirt.cpus = 2

            script += <<-SCRIPT
bash sudo su || bash -c 'sudo su'
SCRIPT
          elsif /(?i:k8s-.*)/.match(host['name'])
            #libvirt.storage :file, :size => '20G', :type => 'qcow2'
            boot_network = {'network' => 'mgmt'}
            libvirt.boot boot_network
            libvirt.boot 'hd'

            override.vm.synced_folder '.', '/vagrant', id: "vagrant-root", disabled: true
          end
        end

        if host.key?("ram")
          libvirt.memory = host["ram"]
        end
      end

      srv.vm.provider :virtualbox do |v, override|
        override.vm.box = host["box"]["vbox"]

        if /(?i:veos)/.match(host['box']['vbox'])
          v.customize [
            'modifyvm', :id,
            '--cpus', '2'
          ]
        end

        if /provisioner/.match(host['name'])
          override.vm.synced_folder '.', '/vagrant', id: "vagrant-root", disabled: true
          override.vm.synced_folder '.', '/provisioning', type: 'rsync',
            rsync__exclude: [ ".gitignore", ".git/", "./misc", "packer-k8snode-build", "packer-provisioner-build", "packer-trunk-build", "packer-veoslibvirt-build", ".vagrant", "*.qcow2", "*.vmdk", "*.box" ]
        else
          override.vm.synced_folder '.', '/vagrant', id: "vagrant-root", disabled: true
        end

        if /(?i:k8s-.*)/.match(host['name'])
          v.customize [
            'modifyvm', :id,
            '--nicbootprio2', '1',
            '--boot1', 'disk',
            '--boot2', 'net',
            '--boot3', 'none',
            '--boot4', 'none'
          ]

          if File.exist?('machines/' + host['name'] + '.vmdk')
            File.delete('machines/' + host['name'] + '.vmdk')
          end

          if File.exist?('machines/' + host['name'] + '-flat.vmdk')
            File.delete('machines/' + host['name'] + '-flat.vmdk')
          end

          v.customize [
            'createhd',
            '--filename', 'machines/' + host['name'],
            '--format', 'VMDK',
            '--size', 20480,
            '--variant', 'Fixed'
          ]
          v.customize [
            'storageattach', :id,
            '--storagectl', "LsiLogic",
            '--port', 0, '--device', 0,
            '--type', 'hdd', '--medium', 'machines/' + host['name'] + '.vmdk'
          ]
        end

        if host.key?("ram")
          v.memory = host["ram"]
        end
      end

      if host.key?("forwarded_ports")
        host["forwarded_ports"].each do |port|
          srv.vm.network :forwarded_port, guest: port["guest"], host: port["host"], id: port["name"]
        end
      end

      if host.key?("links")
        host["links"].each do |link|
          if link.key?("name")
            if link['name'] == "mgmt"
              $mgmtip = link["ip"]
            end

            srv.vm.provider :libvirt do |libvirt, ov|
              ov.vm.network "private_network",
                libvirt__network_name: link["name"],
                ip: ((link.key?("ip") ? (link["ip"] == "" ? "169.254.1.11" : link["ip"]) : "169.254.1.11")),
                libvirt__network_address: ((/(?i:k8s-.*)/.match(host['name']) && link["name"] == "mgmt") ? "10.0.5.0" : nil),
                type: "static",
                libvirt__forward_mode: "veryisolated",
                auto_config: false,
                libvirt__dhcp_enabled: false,
                libvirt__mtu: 1500,
                model_type: "e1000",
                mac: (link.key?("mac") ? link["mac"] : nil)
            end

            srv.vm.provider :virtualbox do |v, ov|
              ov.vm.network "private_network",
                virtualbox__intnet: link["name"],
                ip: (link.key?("ip") ? link["ip"] : "169.254.1.11"),
                auto_config: false,
                type: ((/(?i:k8s-.*)/.match(host['name']) && link["name"] == "mgmt") ? "dhcp" : "static"),
                mac: (link.key?("mac") ? link["mac"] : nil),
                model_type: "e1000"
            end
          end
        end
      end

      script += <<-SCRIPT
export DEBIAN_FRONTEND=noninteractive
export VAGRANT=1
cp /etc/hosts /tmp/hosts
cat /tmp/hosts | /bin/sed 's/vagrant/'#{host['name']}'/g' > /etc/hosts
cp /etc/hosts /tmp/hosts
cat /tmp/hosts | /bin/sed 's/ubuntu1804\.localdomain/'#{host['name']}'/g' > /etc/hosts
if [ -f /provisioning/ssh-config ]; then
  mkdir -p /home/vagrant/.ssh
  cp /provisioning/ssh-config /home/vagrant/.ssh/config
fi
SCRIPT

      if /(?i:veos)/.match(host['box']['vbox'])
        script += <<-SCRIPT
FastCli -p 15 -c "configure
hostname $1
interface Ethernet1
no switchport
ip address $2 255.255.255.0
wr mem"
SCRIPT

        args.push($mgmtip)
      else
        script += <<-SCRIPT
hostnamectl set-hostname $1
SCRIPT
      end

      srv.vm.provision "shell" do |s|
        s.privileged = /(?i:veos)/.match(host['box']['vbox']) ? false : true
        s.inline = script
        s.args = args
      end
    end
  end
end
