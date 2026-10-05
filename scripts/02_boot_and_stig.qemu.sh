#!/usr/bin/env bash
set -euo pipefail
source ../.env

echo "Booting VM in background with KVM acceleration..."
/usr/libexec/qemu-kvm -m 2048 -smp 2 -enable-kvm -cpu host -machine q35 \
    -drive file="${QCOW_FILE}",if=virtio \
    -cdrom seed.iso \
    -net nic -net user,hostfwd=tcp::${SSH_PORT}-:22 \
    -display none -daemonize

echo "Waiting for Cloud-Init and SSH to initialize..."
until ssh -p "${SSH_PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${SSH_USER}@localhost" uptime; do
    sleep 5
done

echo "Running Ansible STIG Playbook..."
cd ../ansible
ansible-playbook -i inventory.ini stig-apply.yml
