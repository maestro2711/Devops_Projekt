terraform {
    required_providers {
       libvirt = {
            source  = "dmacvicar/libvirt"
            version = ">=0.6.0"
        }
    }
}
provider "libvirt" {
    uri = "qemu:///system"
}
# Create a new Libvirt volume based on the cloud ubuntu image
resource "libvirt_volume" "ubuntu_image" {
  source = "/home/cantona/devops/Devops_Projekt/ubuntu-20.04-server-cloudimg-amd64.img"
  name   = "ubuntu-20.04-server-cloudimg-amd64"
  pool   = "default"
  format = "qcow2"
}
# Create a new Libvirt cloudinit disk for the admin user
resource "libvirt_cloudinit_disk" "cloudinit" {
  name           = "admin-vm-cloudinit.iso"
  user_data      = <<-EOF
    
    users:
      - name: admin
        ssh_authorized_keys:
          - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM6+S+dC1DOn69m3EghpyvnbmRRAeVN6BPSbCgNcudTk cantona@cantona-OptiPlex-9020
        sudo: ['ALL=(ALL) NOPASSWD:ALL']
        groups: sudo
        shell: /bin/bash
  EOF
  pool = "default"
}

# Create a new Libvirt vm using the Ubuntu 
resource "libvirt_domain" "admin-vm" {
    name   = "admin-vm"
    memory = "2048"
    vcpu   = 2
    
    disk {
        volume_id = libvirt_volume.ubuntu_image.id
    }
    
    network_interface {
        network_name = "default"
       
    }
    
    cloudinit = libvirt_cloudinit_disk.cloudinit.id
    
    graphics {
        type        = "spice"
        autoport    = true
        listen_type = "address"
    }
  
}
