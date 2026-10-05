#!/usr/bin/env bash
# Execute this script directly on the Proxmox host
set -euo pipefail
source ../.env

echo "Creating Proxmox VM template ${PROXMOX_VMID}..."
qm create "${PROXMOX_VMID}" --name "Rocky9-STIG" --memory 2048 --cores 2 --net0 virtio,bridge="${PROXMOX_BRIDGE}"
qm importdisk "${PROXMOX_VMID}" "${QCOW_FILE}" "${PROXMOX_STORAGE}"
qm set "${PROXMOX_VMID}" --scsihw virtio-scsi-pci --scsi0 "${PROXMOX_STORAGE}:vm-${PROXMOX_VMID}-disk-0"
qm set "${PROXMOX_VMID}" --ide2 "${PROXMOX_STORAGE}:cloudinit"
qm set "${PROXMOX_VMID}" --boot c --bootdisk scsi0
qm set "${PROXMOX_VMID}" --serial0 socket --vga serial0
qm set "${PROXMOX_VMID}" --agent 1
# Ensure FIPS kernel panics do not occur by setting host CPU architecture
qm set "${PROXMOX_VMID}" --cpu host
qm template "${PROXMOX_VMID}"
