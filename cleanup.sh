#!/bin/bash
set -e

VM_NAME="admin-vm"
POOL="default"

echo "🔨 Entferne VM '$VM_NAME' falls vorhanden..."
virsh destroy "$VM_NAME" 2>/dev/null || true
virsh undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true

echo "🧹 Lösche alte Volumes..."
virsh vol-delete "${VM_NAME}-cloudinit.iso" --pool "$POOL" 2>/dev/null || true
virsh vol-delete "ubuntu-20.04-server-cloudimg-amd64" --pool "$POOL" 2>/dev/null || true

echo "🧼 Lösche OpenTofu-Cache & Zustand..."
rm -rf .tofu tofu.tfstate*

echo "✅ Fertig. Jetzt kannst du 'tofu init && tofu apply' ausführen."
