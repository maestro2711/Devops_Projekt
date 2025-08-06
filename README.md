# Devops_Projekt

## Provisioning local VMs with OpenTofu + libvirt

You can use OpenTofu with the libvirt provider exactly as with Terraform.
💡 Summary of steps:

    Install OpenTofu

    Install KVM/libvirt

    Install the libvirt provider for tofu

    Write tofu code (HCL)

    Run with tofu init, tofu apply

# Install OpenTofu for Linux Ubuntu

use this command.
```sh
    curl -s https://apt.opentofu.org/install.sh | sudo bash
    sudo apt update
    sudo apt install tofu
```

## install Kvm and libvirt and tools

```sh
    sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
```
## Add Your User to the libvirt and kvm Groups

```sh
    sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER
```

## activate the group change without rebooting:

```sh
    newgrp libvirt
newgrp kvm
```
## Enable and Start libvirtd 

```sh
    sudo systemctl enable --now libvirtd
```
## Verify Installation

```sh
    virsh list --all
```
## install default pool for volume:
 ```sh
     virsh pool-define-as --name default --type dir --target /var/lib/libvirt/images/
virsh pool-build default
virsh pool-start default
virsh pool-autostart default
```
## install mkisofs tools to producte an Cloud-Init-ISO  

```sh
     sudo apt update
sudo apt install genisoimage
```
## how to solve problem with permession denied?
```sh
     sudo apt install apparmor apparmor-utils
     sudo aa-complain /etc/apparmor.d/libvirt/TEMPLATE.qemu
     sudo systemctl stop apparmor
     sudo systemctl restart libvirtd
```
## install tool to monitoring system
```sh
    sudo apt install cockpit
    sudo install cockpit-machines
```
## show the Ip adress from a VM
```sh
     virsh domifaddr dev-server-1
```
## we want to inkcrement the number of server by boot(  apply) 
```sh
     tofu apply -var="dev_count=3" -var="preprod_count=1" -var="prod_count=5"
```
## jedes mal when wir das kubernetes apt repository aktualisieren möchten , müssen wir immer das vorherige reository löschen
```sh
     sudo rm -f /etc/apt/sources.list.d/kubernetes.list
```
