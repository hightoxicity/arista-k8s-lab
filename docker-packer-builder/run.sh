#!/bin/bash

sudo docker run \
  --interactive=true \
  --network=host \
  --privileged=true \
  --mount type=bind,source="$(pwd)"/../../arista-k8s-lab,target=/arista-k8s-lab \
  hightoxicity/packer-builder
