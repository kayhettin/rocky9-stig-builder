#!/usr/bin/env bash
set -euo pipefail
source ../.env

if [[ ! -f "${MINIMAL_ISO_FILE}" ]]; then
    echo "Downloading Minimal ISO..."
    wget -qO "${MINIMAL_ISO_FILE}" "${ROCKY_MINIMAL_ISO_URL}"
fi

echo "Templating Kickstart..."
envsubst < ../configs/kickstart/stig-baremetal.ks.template > stig-baremetal.ks

echo "Remastering ISO..."
mkksiso --ks stig-baremetal.ks "${MINIMAL_ISO_FILE}" "${OUTPUT_ISO_FILE}"
rm -f stig-baremetal.ks

echo "Baremetal artifact ${OUTPUT_ISO_FILE} generated."
