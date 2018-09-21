SHELL := /bin/bash

all: clean build install

build:
	cd ${CURDIR}; \
	packer build -var-file=variables-vbox.json k8snode-vbox.json; \
	packer build -parallel=true -var-file=variables-qemu.json k8snode-qemu.json;

install:
	VAGRANT_VBOX_PATH="${CURDIR}/output-vagrant-vbox/virtualbox-k8snode.box"; \
	VAGRANT_QEMU_PATH="${CURDIR}/output-vagrant-qemu/libvirt-k8snode.box"; \
	echo -e "Looking for boxes at\n\t- $${VAGRANT_VBOX_PATH}\n\t- $${VAGRANT_QEMU_PATH}"; \
	if [ -f "$${VAGRANT_VBOX_PATH}" ]; then \
	  echo "Removing $${VAGRANT_VBOX_PATH} from vagrant if present..."; \
	  vagrant box remove virtualbox-k8snode --force || true; \
	  echo "Adding $${VAGRANT_VBOX_PATH} to vagrant"; \
	  vagrant box add file://$${VAGRANT_VBOX_PATH} --name virtualbox-k8snode; \
	fi; \
	if [ -f "$${VAGRANT_QEMU_PATH}" ]; then \
          virsh vol-delete --pool default libvirt-k8snode_vagrant_box_image_0.img || true; \
	  echo "Removing $${VAGRANT_QEMU_PATH} from vagrant if present..."; \
	  vagrant box remove libvirt-k8snode --force || true; \
	  echo "Adding $${VAGRANT_QEMU_PATH} to vagrant"; \
	  vagrant box add file://$${VAGRANT_QEMU_PATH} --name libvirt-k8snode; \
	fi;

clean:
	cd ${CURDIR}; \
	rm -rf output-qemu-qcow2 output-qemu-raw output-vagrant-qemu output-vagrant-vbox;
