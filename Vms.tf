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

#vm-configuration variables
variable "dev_count" {
  type    = number
  default = 2
}

variable "preprod_count" {
  type    = number
  default = 2
}

variable "prod_count" {
  type    = number
  default = 3
}

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

locals {
  vms = flatten([
    for env_name, env in var.environnment : [
      for i in range(
        env_name == "dev" ? var.dev_count :
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


locals {
  vm_map = {
    for vm in local.vms :
    vm.name => vm
  }
}

resource "libvirt_volume" "base" {
  source = "/home/cantona/devops/Devops_Projekt/ubuntu-20.04-server-cloudimg-amd64.img.1"
  name   = "ubuntu-20.04-server-cloudimg-amd64"
  pool   = "default"
  format = "qcow2"
}

resource "libvirt_volume" "vm_disk" {
  for_each = local.vm_map

  name            = "${each.key}-disk"
  base_volume_id  = libvirt_volume.base.id
  pool            = "default"
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  for_each = local.vm_map

  name      = "${each.key}-cloudinit.iso"
  user_data = <<EOF
#cloud-config
hostname: ${each.value.name}
users:
  - name: ubuntu
    ssh-authorized-keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM6+S+dC1DOn69m3EghpyvnbmRRAeVN6BPSbCgNcudTk cantona@cantona-OptiPlex-9020
EOF
}

resource "libvirt_domain" "vms" {
  for_each = local.vm_map

  name   = each.value.name
  memory = each.value.memory
  vcpu   = each.value.vcpu

  disk {
    volume_id = libvirt_volume.vm_disk[each.key].id
  }

  network_interface {
    network_name = "default"
    hostname   = each.value.name
  }

  cloudinit = libvirt_cloudinit_disk.cloudinit[each.key].id

  graphics {
    type        = "spice"
    autoport    = true
    listen_type = "address"
  }
}
