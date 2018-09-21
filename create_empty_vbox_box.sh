#!/bin/bash

BOX_NAME=vbox-empty
BASE_DIR="$(pwd)/machines"
BOX_DIR="${BASE_DIR}/${BOX_NAME}"

mkdir -p ${BASE_DIR} || true
rm "${BASE_DIR}/${BOX_NAME}.box" || true

VBoxManage showvminfo ${BOX_NAME} > /dev/null 2>&1
if [ "$?" -eq "1" ]; then
  VBoxManage createvm --name "${BOX_NAME}" --ostype Ubuntu_64 --basefolder ${BASE_DIR}
  VBoxManage registervm "${BOX_DIR}/${BOX_NAME}.vbox"
  VBoxManage storagectl "${BOX_NAME}" --name "LsiLogic" --add scsi --controller LsiLogic
fi

vagrant package --base ${BOX_NAME} --output "${BASE_DIR}/${BOX_NAME}.box"
