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

## ## Installing kcli

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
+---------------+--------+---------------+--------------------------------------------------------+---------------+---------+
|      Name     | Status |      Ips      |                         Source                         |      Plan     | Profile |
+---------------+--------+---------------+--------------------------------------------------------+---------------+---------+
| lab-bootstrap |  down  |               |                                                        | upi-lab-jgato |  kvirt  |
| lab-installer |   up   | 192.168.129.6 | CentOS-8-GenericCloud-8.4.2105-20210603.0.x86_64.qcow2 | upi-lab-jgato |  kvirt  |
|  lab-master-0 |  down  |               |                                                        | upi-lab-jgato |  kvirt  |
|  lab-master-1 |  down  |               |                                                        | upi-lab-jgato |  kvirt  |
|  lab-master-2 |  down  |               |                                                        | upi-lab-jgato |  kvirt  |
+---------------+--------+---------------+--------------------------------------------------------+---------------+---------+
```

A part from the masters and bootstrap, the lab-installer will act as you usual bastion. There you will proceed with the installation.

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

According to the basedomain, dns entries used later by OCP is created:

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
|                 oauth-openshift.apps.lab.karmalabs.com                |  A   |  0  | 192.168.129.252 (lab-baremetal) |
|       prometheus-k8s-openshift-monitoring.apps.lab.karmalabs.com      |  A   |  0  | 192.168.129.252 (lab-baremetal) |
+-----------------------------------------------------------------------+------+-----+---------------------------------+

```

Understanding the main parameters to create the lab.

```yaml
lab: true                                                                                                                     
version: stable                                                                                                               
tag: "4.9"                                                                                                                    
provisioning_enable: true                                                                                                     
pxe_server: 172.22.0.253                                                                                                      
virtual_protocol: redfish                                                                                                     
virtual_masters: true                                                                                                         
virtual_workers: false                                                                                                        
launch_steps: false                                                                                                           
deploy_openshift: false                                                                                                       
cluster: lab                                                                                                                  
domain: karmalabs.com                                                                                                         
baremetal_cidr: 192.168.129.0/24                                                                                              
baremetal_net: lab-baremetal                                                                                                  
provisioning_net: lab-prov                                                                                                    
virtual_masters_memory: 16384                                                                                                 
virtual_masters_numcpus: 8                                                                                                    
virtual_workers_deploy: false                                                                                                 
api_ip: 192.168.129.253                                                                                                       
ingress_ip: 192.168.129.252                                                                                                   
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
bootstrap_provisioning_mac: aa:aa:aa:aa:bb:06               
```

* pxe_server: it will create a pxe server to be used during cluster bootstrap

* cluster: the name of the cluster, we will use it later also for the install-config.yaml

* domain: the domain name for the cluster and the different services that will be created (api, console, etc)

* baremetal_cidr: it will create the network that will be used by pods

* provisioning_net: 

* api_ip:

* ingress_ip__
