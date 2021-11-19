#! /bin/bash

version_release=4.9
version=4.9.0

mirror="https://mirror.openshift.com/pub/openshift-v4/clients"
wget ${mirror}/ocp/${version}/openshift-client-linux.tar.gz
wget ${mirror}/ocp/${version}/openshift-install-linux.tar.gz
tar -xvf openshift-client-linux.tar.gz
tar -xvf openshift-install-linux.tar.gz
sudo cp openshift-install kubectl oc /usr/bin

oc completion bash > /tmp/openshift
openshift-install completion  bash > /tmp/openshift-install
sudo cp /tmp/openshift-install /etc/bash_completion.d/openshift-install
sudo cp /tmp/openshift /etc/bash_completion.d/openshift

echo "source /etc/bash_completion.d/openshift" >> ~/.bashrc
echo "source /etc/bash_completion.d/openshift-install" >> ~/.bashrc

source ~/.bashrc

mirror_images="https://mirror.openshift.com/pub/openshift-v4"
#wget $mirror_images/dependencies/rhcos/${version_release}/${version}/rhcos-live.x86_64.iso
wget $mirror_images/dependencies/rhcos/${version_release}/${version}/rhcos-live-rootfs.x86_64.img
wget $mirror_images/dependencies/rhcos/${version_release}/${version}/rhcos-live-kernel-x86_64
wget $mirror_images/dependencies/rhcos/${version_release}/${version}/rhcos-live-initramfs.x86_64.img
