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


