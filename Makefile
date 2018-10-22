SHELL := /bin/bash

sub-make:
	make -C vbox-empty-build
	make -C packer-trunk-build
	make -C packer-k8snode-build
	make -C packer-provisioner-build
	make -C packer-veoslibvirt-build

vbox:
	make -C vbox-empty-build
	make -C packer-trunk-build vbox
	make -C packer-k8snode-build vbox
	make -C packer-provisioner-build vbox
#	make -C packer-veoslibvirt-build vbox

qemu:
	make -C packer-trunk-build qemu
	make -C packer-k8snode-build qemu
	make -C packer-provisioner-build qemu
	make -C packer-veoslibvirt-build qemu

