terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">= 0.7.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# VM-Konfiguration pro Umgebung
variable "environnment" {
  default = {
    dev = {
      count  = 1
      memory = 2048
      vcpu   = 2
    }
    preprod = {
      count  = 1
      memory = 4096
      vcpu   = 2
    }
    prod = {
      count  = 3
      memory = 4096
      vcpu   = 2
    }
  }
}

# Flache Liste aller VMs
locals {
  vms = flatten([
    for env_name, env in var.environnment : [
      for i in range(env.count) : {
        name   = "${env_name}-server-${i + 1}"
        memory = env.memory
        vcpu   = env.vcpu
      }
    ]
  ])

  vm_map = {
    for vm in local.vms : vm.name => vm
  }
}

# Basisimage (nur einmal importiert)
resource "libvirt_volume" "base" {
  name   = "ubuntu-base.qcow2"
  source = "/home/cantona/devops/Devops_Projekt/ubuntu-base.qcow2"
  pool   = "default"
  format = "qcow2"
}

# Kopie des Basisimages (jede VM bekommt ihr eigenes Volume)
resource "libvirt_volume" "vm_disk" {
  for_each = local.vm_map

  name           = "${each.key}-disk"
  base_volume_id = libvirt_volume.base.id
  pool           = "default"
  format         = "qcow2"
}

# Cloud-Init ISO
resource "libvirt_cloudinit_disk" "cloudinit" {
  for_each = local.vm_map

  name = "${each.key}-cloudinit.iso"

  user_data = <<EOF
#cloud-config
hostname: ${each.key}
ssh_pwauth: true
users:
  - name: devops
    groups: [sudo]
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    lock_passwd: false
    passwd: "$6$JQiHNGD0eGiZ1FZJ$PXryAEW8o2G0XOefsTjHzz1qVWyKnZYkRDFBRXScrQAaYq.W8d/bEOr/TqHPYtk9N/b8pvhuEPSI7jLbE1t/S0"
    ssh-authorized-keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAnEo8p91gvql3SuwFeeG3sqXmYbwgKyvIsWTh14ugv6 cantona@cantona22
EOF
}

# VMs erzeugen
resource "libvirt_domain" "vms" {
  for_each = local.vm_map

  name   = each.key
  memory = each.value.memory
  vcpu   = each.value.vcpu

  disk {
    volume_id = libvirt_volume.vm_disk[each.key].id
  }

  cloudinit = libvirt_cloudinit_disk.cloudinit[each.key].id

  network_interface {
    network_name = "default"
    hostname     = each.key
  }

  graphics {
    type        = "spice"
    autoport    = true
    listen_type = "address"
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}

# IP-Ausgabe nach Umgebung
locals {
  grouped_ips = {
    dev = [
      for k, vm in libvirt_domain.vms :
      vm.network_interface[0].addresses[0]
      if startswith(k, "dev") && length(vm.network_interface[0].addresses) > 0
    ]
    preprod = [
      for k, vm in libvirt_domain.vms :
      vm.network_interface[0].addresses[0]
      if startswith(k, "preprod") && length(vm.network_interface[0].addresses) > 0
    ]
    prod = [
      for k, vm in libvirt_domain.vms :
      vm.network_interface[0].addresses[0]
      if startswith(k, "prod") && length(vm.network_interface[0].addresses) > 0
    ]
  }
}

output "dev_ips"     { value = local.grouped_ips.dev }
output "preprod_ips" { value = local.grouped_ips.preprod }
output "prod_ips"    { value = local.grouped_ips.prod }
