SHELL := /bin/bash

all: clean build
build: build-qemu build-vbox
clean: clean-qemu clean-vbox
vbox: clean-vbox build-vbox
qemu: clean-qemu build-qemu

build-vbox:
	cd ${CURDIR}; \
        packer build -var-file=variables-vbox.json trunk-vbox.json;

build-qemu:
	cd ${CURDIR}; \
	packer build -var-file=variables-qemu.json trunk-qemu.json; \

clean-vbox:
	cd ${CURDIR}; \
	rm -rf output-virtualbox-iso;

clean-qemu:
	cd ${CURDIR}; \
	rm -rf output-qemu-qcow2;
