output "grouped_ips" {
  value = local.grouped_ips
}
output "ansible_inventory_file" {
  value = local_file.ansible_inventory.filename
}