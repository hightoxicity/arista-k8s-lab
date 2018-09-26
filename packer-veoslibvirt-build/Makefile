SHELL := /bin/bash

all: clean build

build:
	cd ${CURDIR}; \
	qemu-img convert -f vmdk -O qcow2 ../machines/vEOS-lab-4.20.7M-combined.vmdk ../machines/vEOS-lab-4.20.7M-combined.vmdk.qcow2; \
	packer build -parallel=true -var-file=variables-qemu.json veos-qemu.json;

install:
	VAGRANT_QEMU_PATH="${CURDIR}/output-vagrant-qemu/libvirt-veos.box"; \
        echo -e "Looking for boxes at\n\t- $${VAGRANT_QEMU_PATH}"; \
        if [ -f "$${VAGRANT_QEMU_PATH}" ]; then \
          virsh vol-delete --pool default libvirt-veos_vagrant_box_image_0.img || true; \
          echo "Removing $${VAGRANT_QEMU_PATH} from vagrant if present..."; \
          vagrant box remove libvirt-veos --force || true; \
          echo "Adding $${VAGRANT_QEMU_PATH} to vagrant"; \
          vagrant box add file://$${VAGRANT_QEMU_PATH} --name libvirt-veos; \
        fi;

clean:
	cd ${CURDIR}; \
	rm -rf output-qemu-qcow2 output-vagrant-qemu;
