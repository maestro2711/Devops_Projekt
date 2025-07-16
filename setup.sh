#!/bin/bash
set -e

echo "🔁 Lösche alte VM + Volumes..."
virsh destroy admin-vm 2>/dev/null || true
virsh undefine admin-vm --remove-all-storage 2>/dev/null || true
virsh vol-delete ubuntu-20.04-server-cloudimg-amd64 --pool default 2>/dev/null || true
virsh vol-delete admin-vm-cloudinit.iso --pool default 2>/dev/null || true

echo "🧼 Bereinige OpenTofu State..."
rm -rf .terraform terraform.tfstate*

echo "⬇️ Lade Ubuntu-Image falls nicht vorhanden..."
[ -f ubuntu-20.04-server-cloudimg-amd64.img ] || wget https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.img

echo "🔧 Setze Berechtigungen..."
sudo chown libvirt-qemu:kvm ubuntu-20.04-server-cloudimg-amd64.img
sudo chmod 644 ubuntu-20.04-server-cloudimg-amd64.img

echo "✅ Fertig. Jetzt kannst du 'tofu init && tofu apply' ausführen."
