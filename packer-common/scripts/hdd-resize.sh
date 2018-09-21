#!/bin/bash

parted /dev/${HDD_TARGET} resizepart 1 100%
pvresize /dev/${HDD_TARGET}1
lvextend -l +100%FREE /dev/mapper/trunk--vg-root
resize2fs /dev/mapper/trunk--vg-root
