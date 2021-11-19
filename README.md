# Deploy Openshift 4 with baremetal (or VMs) and UPI

Tutorial to deploy Openshift 4 in baremetal with user provisioned infrastructure. It should also work to just deploy OCP4 in a server creating some virtual machines that will emulate baremetal servers. 

When using UPI you are responsible to:

* Provide the host's infrastructure (bootstrap, masters and workers)

* Some stuff about networking, dns, load balancers, dhcp, etc

This tutorial aims to provide some of steps above automatically, but, keeping some manual work that keeps you about learning how to deploy OCP4 when you dont have automatic infrastructure provisioning. 

The tutorial is supported by [kvirt]([GitHub - karmab/kcli: Management tool for libvirt/aws/gcp/kubevirt/openstack/ovirt/vsphere/packet](https://github.com/karmab/kcli)) and the project [GitHub - karmab/kcli-openshift4-baremetal: deploy baremetal ipi using a dedicated vm](https://github.com/karmab/kcli-openshift4-baremetal). 

Basically, it takes this project with an specific plan (that you will have in this repo) to prepare the infrastructure to deploy OCP4 with UPI.

* Creates bootstrap, master and workers nodes and the need it network

* Creates DNS and therefore all the nodes can resolve all the nodes

* Creates the DHCP

* Creates a PXE network to consume the ignition files created during a regular OCP4 installation

You are responsible to:

* Create HTTP and PXE Server

* Some config tuning

This example will create the VMs using libvirt and kcli. This should work in a laptop, or any other server, because we are virtualizing resources need it.

## Installing kcli

Just follow instructions [Here](https://kcli.readthedocs.io/en/latest/#installation)

## Prepare the kcli plan and lab

* Clone the kcli plan [GitHub - karmab/kcli-openshift4-baremetal: deploy baremetal ipi using a dedicated vm](https://github.com/karmab/kcli-openshift4-baremetal)

* By the time, checkout the jgato branch

* Copy kcli_plan.yml and lab-jgato.yml from this repo there

We will use that branch with my modified files from this repo.

## Creating the infrastructure

Using a kcli plan the following will be created:

* Creates bootstrap, master and workers nodes and the need it network

* Creates DNS and therefore all the nodes can resolve all the nodes

* Creates DHCP

* Creates a PXE network to consume the ignition files created during a regular OCP4 installationUsing a kvirt plan, the following will be created:

```bash
kcli create plan -f kcli_plan.yml --paramfile lab.yml upi-lab-jgato
```

This will create:

```bash
kcli list  vms

+---------------+--------+--------------+--------------------------------------------------------+---------------+---------+
|      Name     | Status |     Ips      |                         Source                         |      Plan     | Profile |
+---------------+--------+--------------+--------------------------------------------------------+---------------+---------+
| lab-bootstrap |  down  |              |                                                        | upi-lab-jgato |  kvirt  |
| lab-installer |   up   | 172.22.0.253 | CentOS-8-GenericCloud-8.4.2105-20210603.0.x86_64.qcow2 | upi-lab-jgato |  kvirt  |
|  lab-master-0 |  down  |              |                                                        | upi-lab-jgato |  kvirt  |
|  lab-master-1 |  down  |              |                                                        | upi-lab-jgato |  kvirt  |
|  lab-master-2 |  down  |              |                                                        | upi-lab-jgato |  kvirt  |
+---------------+--------+--------------+--------------------------------------------------------+---------------+---------+
```

A part from the masters and bootstrap, the lab-installer will act as you usual bastion. There you will proceed with the installation.

You can also check the created networks

```bash
kcli list network
Listing Networks...
+---------------+--------+------------------+------+---------------+------+
| Network       |  Type  |       Cidr       | Dhcp |     Domain    | Mode |
+---------------+--------+------------------+------+---------------+------+
| default       | routed | 192.168.122.0/24 | True |    default    | nat  |
| lab-baremetal | routed | 192.168.129.0/24 | True | lab-baremetal | nat  |
| lab-prov      | routed |  172.22.0.0/24   | True |    lab-prov   | nat  |
+---------------+--------+------------------+------+---------------+------+
```

And the dns:

```bash
kcli list dns karmalabs.com

Network karmalabs.com not found. Parsing over all networks
+-----------------------------------------------------------------------+------+-----+---------------------------------+
|                                 Entry                                 | Type | TTL |               Data              |
+-----------------------------------------------------------------------+------+-----+---------------------------------+
|                       api-int.lab.karmalabs.com                       |  A   |  0  | 192.168.129.253 (lab-baremetal) |
|                         api.lab.karmalabs.com                         |  A   |  0  | 192.168.129.253 (lab-baremetal) |
| assisted-image-service-open-cluster-management.apps.lab.karmalabs.com |  A   |  0  | 192.168.129.252 (lab-baremetal) |
|       assisted-service-assisted-installer.apps.lab.karmalabs.com      |  A   |  0  | 192.168.129.252 (lab-baremetal) |
|    assisted-service-open-cluster-management.apps.lab.karmalabs.com    |  A   |  0  | 192.168.129.252 (lab-baremetal) |
|         canary-openshift-ingress-canary.apps.lab.karmalabs.com        |  A   |  0  | 192.168.129.252 (lab-baremetal) |
|            console-openshift-console.apps.lab.karmalabs.com           |  A   |  0  | 192.168.129.252 (lab-baremetal) |
|                       lab-master-0.karmalabs.com                      |  A   |  0  |  192.168.129.20 (lab-baremetal) |
|                       lab-master-1.karmalabs.com                      |  A   |  0  |  192.168.129.21 (lab-baremetal) |
|                       lab-master-2.karmalabs.com                      |  A   |  0  |  192.168.129.22 (lab-baremetal) |
|                 oauth-openshift.apps.lab.karmalabs.com                |  A   |  0  | 192.168.129.252 (lab-baremetal) |
|       prometheus-k8s-openshift-monitoring.apps.lab.karmalabs.com      |  A   |  0  | 192.168.129.252 (lab-baremetal) |
+-----------------------------------------------------------------------+------+-----+---------------------------------+
```

you can try it using the dns server installed in 192.168.129.1

```bash
dig api.lab.karmalabs.com @192.168.129.1
; <<>> DiG 9.16.21-RH <<>> api.lab.karmalabs.com @192.168.129.1
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 19456
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;api.lab.karmalabs.com.         IN      A

;; ANSWER SECTION:
api.lab.karmalabs.com.  0       IN      A       192.168.129.253

;; Query time: 0 msec
;; SERVER: 192.168.129.1#53(192.168.129.1)
;; WHEN: Wed Nov 17 16:59:42 CET 2021
;; MSG SIZE  rcvd: 66


dig lab-master-0.karmalabs.com @192.168.129.1

; <<>> DiG 9.16.21-RH <<>> lab-master-0.karmalabs.com @192.168.129.1
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 63059
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;lab-master-0.karmalabs.com.    IN      A

;; ANSWER SECTION:
lab-master-0.karmalabs.com. 0   IN      A       192.168.129.20

;; Query time: 1 msec
;; SERVER: 192.168.129.1#53(192.168.129.1)
;; WHEN: Wed Nov 17 17:00:59 CET 2021
;; MSG SIZE  rcvd: 71
```

and the DHCP entries:

```xml
$ kcli --debug info network lab-baremetal 
    <host ip='192.168.129.22'>                                                                                               
      <hostname>lab-master-2.karmalabs.com</hostname>                                                                         
    </host>                                                                                                                   
    <host ip='192.168.129.21'>
      <hostname>lab-master-1.karmalabs.com</hostname>
    </host>
    <host ip='192.168.129.20'>
      <hostname>lab-master-0.karmalabs.com</hostname>
    </host>
    <host ip='192.168.129.252'> 
      <hostname>apps</hostname> 
        ....
        ....
      <hostname>assisted-service-assisted-installer.apps.lab.karmalabs.com</hostname>
      <hostname>assisted-image-service-open-cluster-management.apps.lab.karmalabs.com</hostname>
    </host>
    <host ip='192.168.129.253'> 
      <hostname>api</hostname>
      <hostname>api.lab.karmalabs.com</hostname>
      <hostname>api-int.lab.karmalabs.com</hostname>
    </host>
```

Understanding the main parameters to create the lab.

```yaml
lab: true                                                                                                                     
version: stable                                                                                                               
tag: "4.9"                                                                                                                    
virtual_masters: true                                                                                                         
virtual_workers: false                                                                                                        
cluster: lab                                                                                                                  
domain: karmalabs.com         
### Network for the different vms                                                                                                
baremetal_cidr: 192.168.129.0/13                                                                                              
baremetal_net: lab-baremetal     
###

### provisioning_net with UPI created the PXE network ###   
provisioning_enable: true  
pxe_server: 172.22.0.253                                                                                
provisioning_net: lab-prov      
bootstrap_provisioning_mac: aa:aa:aa:aa:bb:06            
###

virtual_masters_memory: 16384                                                                                                 
virtual_masters_numcpus: 8                                                                                                    
virtual_workers_deploy: false                                                                                                 
### with baremetal api_ip e ingress use different ips
api_ip: 192.168.129.253                                                                                                       
ingress_ip: 192.168.129.252  
### 
keys: [<paste_here_pub_key]                                                                                                 
baremetal_ips:                                                                                                                
- 192.168.129.20                                                                                                              
- 192.168.129.21                                                                                                              
- 192.168.129.22                                                                                                              
- 192.168.129.23                                                                                                              
- 192.168.129.24                                                                                                              
- 192.168.129.25                                                                                                              
baremetal_macs:  
- aa:aa:aa:aa:bb:01                                                                                                           
- aa:aa:aa:aa:bb:02                                                                                                           
- aa:aa:aa:aa:bb:03                                                                                                           
- aa:aa:aa:aa:bb:04                                                                                                           
- aa:aa:aa:aa:bb:05                                                                                                           
- aa:aa:aa:aa:bb:06                                                                                                           
```

* provisioning_net, bootstrap_provisioning_mac and pxe_server: configures the PXE server

* cluster: the name of the cluster, we will use it later also for the install-config.yaml

* domain: the domain name for the cluster and the different services that will be created (api, console, etc)

* baremetal_cidr: it will create the network that will be used by the VMs

* api_ip & ingress_ip for the load balance that will balance between masters and workers accordingly 

Now you should ssh to the lab-installer to start preparing the installation of openshift. 

```bash
kcli ssh lab-installer
```

### Inside lab-installer

Clone this repo:

```bash
sudo dnf install -y git
git clone https://github.com/jgato/deploy-ocp4-with-baremetal-upi.git
cd deploy-ocp4-with-baremetal-upi
./get_packages.sh
```

* Download the clients and RHCOS images. You can use the scripts from repo

```bash
./get_clients_and_images.sh
```

* Get the pull-secret Go to [Red Hat OpenShift Cluster Manager](https://cloud.redhat.com/openshift/install/metal/user-provisioned), use your credentials and pull the secret to a file, ex: pull-secret. You can pretty format the file

* Create an ssh key to access from the lab-installer

```bash
ssh-keygen -t rsa
Generating public/private rsa key pair.
Enter file in which to save the key (/home/jgato/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/jgato/.ssh/id_rsa
Your public key has been saved in /home/jgato/.ssh/id_rsa.pub
```

Test that created dns entries works also in this host:

```bash
dig lab-master-0.karmalabs.com
; <<>> DiG 9.11.26-RedHat-9.11.26-6.el8 <<>> lab-master-0.karmalabs.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 48399
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;lab-master-0.karmalabs.com.    IN      A

;; ANSWER SECTION:
lab-master-0.karmalabs.com. 0   IN      A       192.168.129.20

;; Query time: 0 msec
;; SERVER: 192.168.129.1#53(192.168.129.1)
;; WHEN: mié nov 17 16:11:49 UTC 2021
;; MSG SIZE  rcvd: 71
```

And some more:

```bash
dig +noall +answer  api.lab.karmalabs.com
api.lab.karmalabs.com.  0       IN      A       192.168.129.253

dig +noall +answer  api-int.lab.karmalabs.com
api-int.lab.karmalabs.com. 0    IN      A       192.168.129.253

dig +noall +answer lab-bootstrap.karmalabs.com
lab-bootstrap.karmalabs.com. 0  IN      A       192.168.129.24
```

This tutorial is based on libvirt that does not support dns wildcards. So we cannot have:

```bash
dig +noall +answer  random-app.apps.lab.karmalabs.com
```

FIX: We will fail about accessing any deployed workload

#### Prepare ignition files

Lets create the install-config.yaml (you can use the template provided in this repo)

```bash
mkdir ocp4-upi
cp deploy-ocp4-with-baremetal-upi/install-config.yaml.template ocp4-upi/install-config.yaml
cd ocp4-upi
vi install-config.yaml

apiVersion: v1
baseDomain: example.com
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 0
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 3
metadata:
  name: ocp4
networking:
  clusterNetwork:
  - cidr: 192.168.0.0/14
    hostPrefix: 23
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
fips: false
pullSecret: |
  <CHANGE_ME_KEEPING_THE_INDENTATION_LEVEL>
sshKey: |
  <CHANGE_ME_KEEPING_THE_INDENTATION_LEVEL>
```

Important:

* Paste the pull-secret and your created ssh key

Now create the manifests and ignition files:

* With manifests you can make some custom modifications for the installation. Not covered in this tutorial

* The ignition files will be need it later for the pxe boot

Make a copy of you install-config.yaml



```bash

$ openshift-install create manifests --dir=.
INFO Consuming Install Config from target directory                                                                           
WARNING Making control-plane schedulable by setting MastersSchedulable to true for Scheduler cluster settings 
INFO Manifests created in: manifests and openshift 


$ openshift-install create ignition-configs --dir=.
INFO Consuming Master Machines from target directory 
INFO Consuming Openshift Manifests from target directory 
INFO Consuming Worker Machines from target directory 
INFO Consuming OpenShift Install (Manifests) from target directory 
INFO Consuming Common Manifests from target directory 
INFO Ignition-Configs created in: . and auth      

```

Now you have the igntion files to boot coreos installer.



#### Create the Load Balancer

The LB will be in charge of balancing kube-apiserver between the control-planes and *.apps for the ingress.  How does it works? How the LB is pointed?

* During the 'plan' configuration the values for the a 'api_ip' and 'ingres_ip' where set to point to the lab-installer host.

* With this ips, the DNS is configured with these entries:
  
  * api-int.lab.karmalabs.com -> api_ip -> bootstrap and control-planes
  
  * api.lab.karmalabs.com -> api_ip -> bootstrap and control-planes
  
  * *.apps.lab.karmalabs.com -> ingress_ip -> (usually) workers

We will use haproxy for the LB, that it is installed with the 'get_packages.sh_' script.

Edit `/etc/haproxy/haproxy.cfg`:

```yaml
listen api-server-6443
  bind *:6443
  mode tcp
  server lab-bootstrap lab-bootstrap.karmalabs.com:6443 check inter 1s backup


  server lab-master-0  lab-master-0.karmalabs.com:6443 check inter 1s
  server lab-master-1  lab-master-1.karmalabs.com:6443 check inter 1s
  server lab-master-2  lab-master-2.karmalabs.com:6443 check inter 1s

listen machine-config-server-22623
  bind *:22623
  mode tcp
  server lab-bootstrap lab-bootstrap.karmalabs.com:22623 check inter 1s backup

  server lab-master-0  lab-master-0.karmalabs.com:22623 check inter 1s
  server lab-master-1  lab-master-1.karmalabs.com:22623 check inter 1s
  server lab-master-2  lab-master-2.karmalabs.com:22623 check inter 1s

listen ingress-router-443
  bind *:443
  mode tcp
  balance source

  server lab-master-0  lab-master-0.karmalabs.com:443 check inter 1s
  server lab-master-1  lab-master-1.karmalabs.com:443 check inter 1s
  server lab-master-2  lab-master-2.karmalabs.com:443 check inter 1s

listen ingress-router-80
  bind *:80
  mode tcp
  balance source

  server lab-master-0  lab-master-0.karmalabs.com:80 check inter 1s
  server lab-master-1  lab-master-1.karmalabs.com:80 check inter 1s
  server lab-master-2  lab-master-2.karmalabs.com:80 check inter 1s
```

you have an example in this repo.

Notice you maybe have to tune it to point to the correctly. In this example we dont have workers. So the workloads will run in the control-plane, and this is why we send all traffic there. But usually, ingress-router will point to the name of the hosts with workers.

Bootstrap entries can be deleted after bootstrap phase

Check no errors

```bash
haproxy -c -f /etc/haproxy/haproxy.cfg
Configuration file is valid
```

if you have an selinux problem loading haproxy

```bash
setsebool -P haproxy_connect_any on
```

Restart the service and enable

```bash
systemctl reload haproxy
systemctl enable haproxy
```

#### Create the HTTP server

Install the http server.  ('get_packages.sh' script do it for you)

Edit '/etc/httpd/conf/httpd.conf' to listen on 8080, because the 80 port is used by the load balancer.

Restart the service and enable it.

```bash
systemctl reload httpd
systemctl enable httpd
```

Usual exported files under /var/www/html. So we will create the structure for the ignition files.

```bash
mkdir -p /var/www/html/openshift4/4.9.0/ignitions
mkdir -p /var/www/html/openshift4/4.9.0/images
```

Copy the previously created ignition files:

```bash
cp *.ign /var/www/html/openshift4/4.9.0/ignitions
```

Ensure these have right perms

```bash
chmod -R o+r /var/www/html/openshift4/4.9.0/ignitions
```

check it:

```bash
curl localhost:8080/openshift4/4.9.0/ignitions/master.ign \ 
> -o /tmp/master.ign
```

The script get_clients_and_images.sh download also the RHCOS images that we will need later. So lets copy them

```bash
cp rhcos-live* /var/www/html/openshift4/4.9.0/images/
```

#### Installing RHCOS by using an ISO image

**this part is not finished. But you can install with pxe**

#### Installing with PXE

Install the TFTP server. 'get_packages.sh' script do it for you.

You have to configure the different pxe files for each type of host (bootstrap, master, worker). In this example we dont have workers, so you dont need it.

```bash
systemctl enable tftp
systemctl start tftp
```

The get_packages.sh script has downloaded also some files we need for the pxeboot server.

```bash
cp /usr/share/syslinux/{pxelinux.0,ldlinux.c32} /var/lib/tftpboot/
```

Now we have to create the configuration files (differents depending on the kind of host: bootstrap, master, worker). Basically they are similar but with different ignition files.

```bash
mkdir /var/lib/tftpboot/pxelinux.cfg
```

There we will place the default config. You can find an example in this repo but edit it to point check the urls to download the images.

```bash
DEFAULT pxeboot
TIMEOUT 20
PROMPT 0
LABEL pxeboot for bootstrap
    KERNEL http://172.22.0.253:8080/openshift4/4.9.0/images/rhcos-live-kernel-x86_64
    APPEND initrd=http://172.22.0.253:8080/openshift4/4.9.0/images/rhcos-live-initramfs.x86_64.img coreos.live.rootfs_url=http://172.22.0.253:8080/openshift4/4.9.0/images/rhcos-live-rootfs.x86_64.img  coreos.inst.install_dev=/dev/sda coreos.inst.ignition_url=http://172.22.0.253:8080/openshift4/4.9.0/ignitions/bootstrap.ign
```

You can see it will download several images we have made available through http in a previous step. Check the urls and ips are oka. The IP has to point to the IP of the lab-installer. 

You also can see this example only downloads the ignition for the bootstrap one. We need to create similar ones with the other ignitions. How the system will know which one to use with each host? because of the MAC. You have to create one for each MAC.

For the bootstrap we can call the file default and place it in /var/lib/tftpboot/pxelinux.cfg

Then we create the ones for the masters (here we dont have workers)

```bash
DEFAULT pxeboot
TIMEOUT 20
PROMPT 0
LABEL pxeboot for master
    KERNEL http://172.22.0.253:8080/openshift4/4.9.0/images/rhcos-live-kernel-x86_64
    APPEND initrd=http://172.22.0.253:8080/openshift4/4.9.0/images/rhcos-live-initramfs.x86_64.img coreos.live.rootfs_url=http://172.22.0.253:8080/openshift4/4.9.0/images/rhcos-live-rootfs.x86_64.img  coreos.inst.install_dev=/dev/sda coreos.inst.ignition_url=http://172.22.0.253:8080/openshift4/4.9.0/ignitions/master.ign
```

Create three different files with that content named (example according to the lab config, all the MAC address have to append 01-MAC in the following way)

* 01-aa-aa-aa-aa-bb-01

* 01-aa-aa-aa-aa-bb-02

* 01-aa-aa-aa-aa-bb-03

And 01-aa-aa-aa-aa-bb-04 could contain the content for the bootstrap

### Init lab-bootstrat with pxe

Out the lab-installer, in the host

```bash
kcli start vm lab-bootstrap
sudo virt-viewer
```

and choose the lab-bootstrap host.

Maybe you will have to send a control+alt+del and interrupt boot seq to choose pxe.

If everything goes ok it will start the bootstrap installation.





# Troubleshooting

## Networking issues after suspend

The lab-installer vm dont have internet access

Restart VM

```bash
kcli restart vm lab-installer
```
