# Deploy Openshift 4 with baremetal (or VMs) and UPI

Tutorial to deploy Openshift 4 in baremetal with user provisioned infrastructure. It should also work to just deploy OCP4 in a server creating some virtual machines that will emulate baremetal servers. 

When using UPI you are responsible to:

* Provide the host's infrastructure (bootstrap, masters and workers)

* Some stuff about networking, dns, load balancers, dhcp, etc

This tutorial aims to provide some of steps above automatically, but, keeping some manual work that keeps you about learning how to deploy OCP4 when you dont have automatic infrastructure provisioning. 

The tutorial is supported by [kvirt]([GitHub - karmab/kcli: Management tool for libvirt/aws/gcp/kubevirt/openstack/ovirt/vsphere/packet](https://github.com/karmab/kcli)) and the project [GitHub - karmab/kcli-openshift4-baremetal: deploy baremetal ipi using a dedicated vm](https://github.com/karmab/kcli-openshift4-baremetal). Basically, it takes this project with an specific plan to prepare the infrastructure to deploy OCP4 with UPI.

* Creates bootstrap, master and workers nodes and the need it network

* Creates DNS and therefore all the nodes can resolve all the nodes

* Creates a PXE network to consume the ignition files created during a regular OCP4 installation

## Installing kcli

Just follow instructions [Here](https://kcli.readthedocs.io/en/latest/#installation)

## Creating the infrastructure

Using a kcli plan the following will be created:

* Creates bootstrap, master and workers nodes and the need it network

* Creates DNS and therefore all the nodes can resolve all the nodes

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

* Download the clients. You can use the scripts from repo

```bash
./get_clients.sh
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

Lets create the install-config.yaml

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

### Create the Load Balancer

### Create the HTTP server

### Create the TFTP and the
