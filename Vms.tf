terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">=0.7.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# VM-Anzahlen je Umgebung
variable "dev_count"     { default = 2 }
variable "preprod_count" { default = 2 }
variable "prod_count"    { default = 4}

# Konfigurationsprofil pro Umgebung
variable "environnment" {
  default = {
    dev = {
      memory = 2048
      vcpu   = 2
    }
    preprod = {
      memory = 4096
      vcpu   = 4
    }
    prod = {
      memory = 4096
      vcpu   = 4
    }
  }
}

# Liste aller VMs (flach)
locals {
  vms = flatten([
    for env_name, env in var.environnment : [
      for i in range(
        env_name == "dev"     ? var.dev_count     :
        env_name == "preprod" ? var.preprod_count :
                                var.prod_count
      ) : {
        name   = "${env_name}-server-${i + 1}"
        memory = env.memory
        vcpu   = env.vcpu
      }
    ]
  ])
}

# Map für Terraform-Iteration
locals {
  vm_map = {
    for vm in local.vms : vm.name => vm
  }
}

# Basis-Image (unverändert)
resource "libvirt_volume" "base" {
  name   = "ubuntu-20.04-server-cloudimg-amd64"
  source = "/home/cantona/devops/Devops_Projekt/ubuntu-20.04-server-cloudimg-amd64.img.1"
  pool   = "default"
  format = "qcow2"
}

# Disk: direkt aus Basis-Image kopieren (nicht base_volume_id!)
resource "libvirt_volume" "vm_disk" {
  for_each = local.vm_map

  name   = "${each.key}-disk"
  source = "/home/cantona/devops/Devops_Projekt/ubuntu-20.04-server-cloudimg-amd64.img.1"
  pool   = "default"
  format = "qcow2"
}

# Cloud-Init-ISO inkl. Benutzerkonfiguration
resource "libvirt_cloudinit_disk" "cloudinit" {
  for_each = local.vm_map

  name = "${each.key}-cloudinit.iso"

  user_data = <<EOF
#cloud-config
hostname: ${each.value.name}
ssh_pwauth: true

users:
  - name: devops
    passwd: $6$JQiHNGD0eGiZ1FZJ$PXryAEW8o2G0XOefsTjHzz1qVWyKnZYkRDFBRXScrQAaYq.W8d/bEOr/TqHPYtk9N/b8pvhuEPSI7jLbE1t/S0
    lock_passwd: false
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAnEo8p91gvql3SuwFeeG3sqXmYbwgKyvIsWTh14ugv6 cantona@cantona22

datasource:
  None:
    instance-id: ${each.key}
    local-hostname: ${each.value.name}
EOF
}

# Virtuelle Maschinen
resource "libvirt_domain" "vms" {
  for_each = local.vm_map

  name   = each.value.name
  memory = each.value.memory
  vcpu   = each.value.vcpu

  disk {
    volume_id = libvirt_volume.vm_disk[each.key].id
  }

  cloudinit = libvirt_cloudinit_disk.cloudinit[each.key].id

  network_interface {
    network_name = "default"
    hostname     = each.value.name
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

# Gruppierung der IP-Adressen
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
# Ausgabe der IP-Adressen
output "dev_ips" {
  value = local.grouped_ips.dev
}