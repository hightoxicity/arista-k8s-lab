FROM ubuntu:18.04
MAINTAINER FOUCHARD Tony <t.fouchard@qwant.com>
RUN apt-get update
RUN apt-get install unzip curl virtualbox qemu-kvm libvirt-bin -y
#RUN adduser $USER libvirtd
WORKDIR /tmp
RUN curl https://releases.hashicorp.com/packer/1.3.1/packer_1.3.1_linux_amd64.zip -o /tmp/packer_1.3.1_linux_amd64.zip
RUN echo "254cf648a638f7ebd37dc1b334abe940da30b30ac3465b6e0a9ad59829932fa3 packer_1.3.1_linux_amd64.zip" | sha256sum -c -
RUN unzip packer_1.3.1_linux_amd64.zip -d /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/packer"]
