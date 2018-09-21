SHELL := /bin/bash

all: clean build

build:
	cd ${CURDIR}; \
	packer build -var-file=variables-qemu.json trunk-qemu.json; \
        packer build -var-file=variables-vbox.json trunk-vbox.json;

clean:
	cd ${CURDIR}; \
	rm -rf output-qemu-qcow2; rm -rf output-virtualbox-iso;
