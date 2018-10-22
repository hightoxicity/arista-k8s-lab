SHELL := /bin/bash

all: clean build install
clean: clean-vbox clean-qemu
build: build-vbox build-qemu
install: install-vbox install-qemu
vbox: clean-vbox build-vbox install-vbox
qemu: clean-qemu build-qemu install-qemu

build-vbox:
	cd ${CURDIR}; \
	packer build -var-file=variables-vbox.json provisioner-vbox.json; \

build-qemu:
	cd ${CURDIR}; \
	packer build -parallel=true -var-file=variables-qemu.json provisioner-qemu.json;

install-vbox:
	VAGRANT_VBOX_PATH="${CURDIR}/output-vagrant-vbox/virtualbox-provisioner.box"; \
	echo -e "Looking for boxes at\n\t- $${VAGRANT_VBOX_PATH}\n\t-"; \
	if [ -f "$${VAGRANT_VBOX_PATH}" ]; then \
	  echo "Removing $${VAGRANT_VBOX_PATH} from vagrant if present..."; \
	  vagrant box remove virtualbox-provisioner --force || true; \
	  echo "Adding $${VAGRANT_VBOX_PATH} to vagrant"; \
	  vagrant box add file://$${VAGRANT_VBOX_PATH} --name virtualbox-provisioner; \
	fi; \

install-qemu:
	VAGRANT_QEMU_PATH="${CURDIR}/output-vagrant-qemu/libvirt-provisioner.box"; \
	echo -e "Looking for boxes at\n\t- $${VAGRANT_QEMU_PATH}"; \
	if [ -f "$${VAGRANT_QEMU_PATH}" ]; then \
          virsh vol-delete --pool default libvirt-provisioner_vagrant_box_image_0.img || true; \
	  echo "Removing $${VAGRANT_QEMU_PATH} from vagrant if present..."; \
	  vagrant box remove libvirt-provisioner --force || true; \
	  echo "Adding $${VAGRANT_QEMU_PATH} to vagrant"; \
	  vagrant box add file://$${VAGRANT_QEMU_PATH} --name libvirt-provisioner; \
	fi;

clean-vbox:
	cd ${CURDIR}; \
	rm -rf output-vagrant-vbox;

clean-qemu:
	cd ${CURDIR}; \
	rm -rf output-qemu-qcow2 output-qemu-raw output-vagrant-qemu;
