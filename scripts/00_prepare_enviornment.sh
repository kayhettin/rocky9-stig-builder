#!/usr/bin/env bash
set -euo pipefail
source ../.env

echo "Installing build dependencies..."
sudo dnf install -y ansible-core git qemu-kvm genisoimage lorax

echo "Pulling Ansible STIG role..."
ansible-galaxy role install -r ../ansible/requirements.yml

if [[ ! -f "${SSH_PUB_KEY_PATH}" ]]; then
    echo "Generating temporary build SSH key..."
    ssh-keygen -t rsa -b 4096 -f "${SSH_PUB_KEY_PATH%.*}" -N ""
fi

if [[ ! -f "${QCOW_FILE}" ]]; then
    echo "Downloading Base QCOW2..."
    wget -qO "${QCOW_FILE}" "${ROCKY_QCOW_URL}"
fi
