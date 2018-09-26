SHELL := /bin/bash

sub-make:
	make -C vbox-empty-build
	make -C packer-trunk-build
	make -C packer-k8snode-build
	make -C packer-provisioner-build
	make -C packer-veoslibvirt-build
