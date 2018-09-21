SHELL := /bin/bash

OUTPUT_DIRNAME=output-vbox-empty
BOX_NAME=vbox-empty

all: clean build install

build:
	cd "${CURDIR}"; \
	mkdir -p "${CURDIR}/${OUTPUT_DIRNAME}" || true; \
	VBoxManage createvm --name "${BOX_NAME}" --ostype Ubuntu_64 --basefolder "${CURDIR}/${OUTPUT_DIRNAME}"; \
	VBoxManage registervm "${CURDIR}/${OUTPUT_DIRNAME}/${BOX_NAME}/${BOX_NAME}.vbox"; \
	VBoxManage storagectl ${BOX_NAME} --name "LsiLogic" --add scsi --controller LsiLogic; \
	vagrant package --base ${BOX_NAME} --output ${CURDIR}/${OUTPUT_DIRNAME}/${BOX_NAME}.box;

install:
	cp ${CURDIR}/${OUTPUT_DIRNAME}/${BOX_NAME}.box ${CURDIR}/../machines/

clean:
	cd ${CURDIR}; \
	VBoxManage unregistervm ${BOX_NAME} --delete || true; \
	rm -rf ${CURDIR}/${OUTPUT_DIRNAME} || true;
