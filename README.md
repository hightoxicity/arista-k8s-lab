# arista-k8s-lab: Network Automation Lab around K8S + Arista

## Note

*Due to some limitations with the veos image, we could not have enough bytes throughput to be able to provision our machines.
We decided to replace veos by an open source solution and we chose vyos. Other big constraint was the complexity to retrieve veos image requiring to register near arista. You can find our new solution here: https://github.com/hightoxicity/k8s-prodgrade-lab*

*This project will be no more maintained nor will it be evolving.*

## Project Purpose


Aim of the project is to create a kubernetes cluster self-contained into a local environment (one more).

Advantage of the solution is to reproduce locally a production grade networking.

This lab creates a simple spine-leaf architecture with veos virtual machines.

You will have:
* One spine
* Two leaves
* A k8s master node and a worker node under first leaf
* Another worker node under the second leaf

The lab is based on the following software:
* Arista vEOS
* Vagrant
* VirtualBox/Libvirt
* Ansible
* Kubernetes
* Calico

The network design is a basic leaf/spine topology (AS per rack model) that will be built entirely using eBGP peerings.

The K8S network SDN is a calico full l3 solution ensuring pod networking.

## Launch the lab:

Please register on Arista website and download the following Arista veos virtualbox image on Arista website: vEOS-lab-4.19.7M-virtualbox.box

For libvirt, you should build your own box from the combined vmdk distributed by Arista. We did not succeed trying to run 4.19.7M image with libvirt (kernel panic), so we chose to use 4.20.7M

Copy working images under the machines directory.

### With virtualbox

* vagrant up --provider virtualbox

### With libvirt

* vagrant up spine-1 leaf-1 leaf-2 --provider libvirt --parallel
* vagrant up provisioner --provider libvirt
* vagrant up k8s-master-001 k8s-worker-001 k8s-worker-002 --provider libvirt --parallel
