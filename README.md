# Rocky Linux 9 DISA STIG Image Builder

## Architecture & Objective Overview
This repository provides an automated, idempotent Infrastructure as Code (IaC) pipeline for generating DISA STIG-compliant Rocky Linux 9 artifacts. Because these artifacts are intended for air-gapped/offline networks, the build process is decoupled from the final hypervisor. 

The pipeline generates two distinct deployment artifacts:
1.  **Offline Proxmox Template:** A generalized QCOW2 image hardened via the `ansible-lockdown.rhel9_stig` role in a background, nested QEMU process.
2.  **Bare-metal Bootable ISO:** A remastered minimal ISO utilizing an Anaconda Kickstart to enforce FIPS 140-3 cryptography, STIG-compliant LVM partitioning, and the OpenSCAP security profile during physical hardware provisioning.

## Prerequisites
*   **Operating System:** An internet-connected Linux build environment (Rocky Linux 9 or RHEL 9 recommended)[cite: 2].
*   **Permissions:** The executing user must have `sudo` privileges to install packages[cite: 3, 4].
*   **Hardware Virtualization:** The build machine must have nested virtualization enabled (`vmx` or `svm` CPU flags) to run the QEMU acceleration pipeline[cite: 4, 5].
*   **Network:** Access to standard EL9 repositories, Ansible Galaxy, and Rocky Linux image servers[cite: 2].

## Deployment Instructions

1.  **Clone the Repository & Configure Environment:**
    ```bash
    git clone <repo-url> && cd rocky9-stig-builder
    cp .env.example .env
    # Edit .env to supply your HashiCorp Vault injected secrets for baremetal deployment.
    ```
2.  **Prepare the Host and Download Roles/Images:**
    ```bash
    cd scripts/
    ./00_prepare_environment.sh
    ```
3.  **Build the Proxmox QCOW2 Artifact:**
    ```bash
    ./01_build_cloud_init.sh
    ./02_boot_and_stig_qemu.sh
    ./03_clean_and_export.sh
    ```
    *Transfer the resulting `.qcow2` to your offline Proxmox network via a cross-domain data diode or secure USB media.*[cite: 3]
4.  **Import to Proxmox (Execute on Proxmox Shell):**
    ```bash
    ./04_proxmox_import.sh
    ```
5.  **Build the Bare-metal ISO Artifact:**
    ```bash
    ./05_build_baremetal_iso.sh
    ```
    *Burn the resulting `.iso` to physical media for deployment.*[cite: 12]

## Directory & File Manifest
*   `ansible/`: Contains requirements and playbooks for the `ansible-lockdown` role[cite: 1, 2, 3].
*   `configs/cloud-init/`: Infrastructure to bypass libvirt networking limits by injecting SSH keys and guest agents natively via `genisoimage`[cite: 6, 7].
*   `configs/kickstart/`: Configures OpenSCAP and mandates STIG layout requirements (e.g., `/var/log/audit`, `/tmp`, and `/home` partitioning)[cite: 11].
*   `scripts/`: Sequential, idempotent bash execution steps. 

## Validation & Smoke Testing
1.  **Verify QEMU SSH Responsiveness:**
    Before applying the Ansible playbook, the build scripts validate connectivity and Cloud-Init execution using:
    ```bash
    ssh -p 2222 -o StrictHostKeyChecking=no admin@localhost uptime
    ```
    *Expected Output:* System uptime (e.g., `up 1 min, 0 users, load average: ...`). If it hangs, QEMU is still executing Cloud-Init[cite: 8, 9].
2.  **Verify Proxmox Template Integrity:**
    Clone a VM from the generated Proxmox template and monitor the boot console. A successful boot to the Rocky Linux login prompt confirms FIPS 140-3 cryptography checks passed.

## Troubleshooting / Common Pitfalls
*   **Kernel Panic in Proxmox Clones (`Attempted to kill init! exit code=0x00007f00`):** 
    By default, Proxmox sets VM CPU architectures to `kvm64`. Because the Ansible STIG role strictly enables FIPS mode, the OS requires hardware cryptographic instruction sets (`aes` CPU flags)[cite: 10]. **Fix:** Always ensure the CPU type is set to `host` via the Proxmox UI (Hardware -> Processors) or CLI (`qm set <VMID> --cpu host`) so the guest can access physical hardware acceleration[cite: 10].
*   **QEMU Background Hangs / SSH Connection Refused:** 
    Rocky Linux 9 strictly requires an `x86-64-v2` processor architecture. If QEMU is launched without passing a modern CPU flag, it falls back to a generic model, and the VM will silently crash in the background[cite: 10]. **Fix:** `02_boot_and_stig_qemu.sh` mitigates this by passing `-cpu host -machine q35`[cite: 10].
*   **`virt-customize` Stalls on "Examining the guest..." or Libvirt Permissions Denied:**
    Using `guestfs-tools` requires building nested micro-VMs, which frequently causes permission errors if the image resides in user home directories, or freezes if nested KVM is unavailable[cite: 4, 5, 6]. **Fix:** This repository entirely abandons `virt-customize` in favor of a native Cloud-Init `seed.iso` strategy directly mounted into standard `/usr/libexec/qemu-kvm`[cite: 6, 7, 8].
