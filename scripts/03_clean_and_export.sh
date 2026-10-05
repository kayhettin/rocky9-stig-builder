#!/usr/bin/env bash
set -euo pipefail
source ../.env

echo "Cleaning VM state..."
ssh -p "${SSH_PORT}" -o StrictHostKeyChecking=no "${SSH_USER}@localhost" << 'EOF'
    sudo dnf clean all
    sudo rm -rf /etc/ssh/ssh_host_*
    sudo truncate -s 0 /etc/machine-id
    sudo rm -rf /tmp/* /var/tmp/*
    history -c
    sudo shutdown -h now
EOF

echo "Waiting for VM shutdown..."
while pgrep -f qemu-kvm > /dev/null; do
    sleep 2
done

echo "VM generalized. The artifact ${QCOW_FILE} is ready for offline transfer."
