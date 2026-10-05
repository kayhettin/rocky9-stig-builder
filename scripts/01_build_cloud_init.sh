#!/usr/bin/env bash
set -euo pipefail
source ../.env

echo "Compiling Cloud-Init configuration..."
export SSH_PUB_KEY=$(cat "${SSH_PUB_KEY_PATH}")
envsubst < ../configs/cloud-init/user-data.template > user-data
cp ../configs/cloud-init/meta-data meta-data

echo "Generating Seed ISO..."
genisoimage -output seed.iso -volid cidata -joliet -rock user-data meta-data
rm -f user-data meta-data
