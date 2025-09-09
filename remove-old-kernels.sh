#!/usr/bin/env bash
set -e

PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] remove-old-kernels: $1" >&2
}

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]] && ! command -v sudo &> /dev/null; then
    log "ERROR: This script requires root privileges or sudo"
    exit 1
fi

# Check for required commands
for cmd in uname dpkg awk grep sort apt-get; do
    if ! command -v "$cmd" &> /dev/null; then
        log "ERROR: Required command '$cmd' not found"
        exit 1
    fi
done

log "Starting kernel cleanup process"

# Get the version of the currently running kernel
current_kernel_version=$(uname -r)
log "Current kernel version: $current_kernel_version"

# Define meta-packages to exclude
meta_packages="linux-image-generic linux-image-lowlatency linux-image-raspi linux-image-cloud"

# Get a list of installed kernel images, excluding the current one and meta-packages
log "Scanning for installed kernel packages..."
installed_kernels=$(dpkg --list | grep linux-image | awk '{print $2}' | grep -vE "$current_kernel_version|$meta_packages" | sort -V)

if [[ -z "$installed_kernels" ]]; then
    log "No additional kernel packages found"
else
    log "Found kernel packages: $installed_kernels"
fi

# Get the list of kernels to remove
kernels_to_remove=()
for kernel in $installed_kernels; do
    kernel_version=$(echo $kernel | sed -n 's/linux-image-\([0-9.-]*\)-generic/\1/p')
    if [ ! -z "$kernel_version" ] && dpkg --compare-versions "$kernel_version" lt "$current_kernel_version"; then
        kernels_to_remove+=("$kernel")
    fi
done

# Remove kernels that are older than the current kernel
if [ ${#kernels_to_remove[@]} -gt 0 ]; then
    log "Removing old kernels: ${kernels_to_remove[*]}"
    sudo apt-get purge -y "${kernels_to_remove[@]}"
    log "Successfully removed ${#kernels_to_remove[@]} old kernel(s)"
else
    log "No old kernels to remove"
fi

log "Kernel cleanup completed successfully"
