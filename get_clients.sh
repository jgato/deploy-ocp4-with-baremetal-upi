#! /bin/bash

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


