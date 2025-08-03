locals {
  ansible_inventory = templatefile("${path.module}/inventory.tpl", {
    dev     = local.grouped_ips.dev
    preprod = local.grouped_ips.preprod
    prod    = local.grouped_ips.prod
  })
}

resource "local_file" "ansible_inventory" {
  content  = local.ansible_inventory
  filename = "${path.module}/inventory.ini"
}

