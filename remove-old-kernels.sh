#!/usr/bin/env bash

PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin

# Get the version of the currently running kernel
current_kernel_version=$(uname -r)

# Define meta-packages to exclude
meta_packages="linux-image-generic linux-image-lowlatency linux-image-raspi linux-image-cloud"

# Get a list of installed kernel images, excluding the current one and meta-packages
installed_kernels=$(dpkg --list | grep linux-image | awk '{print $2}' | grep -vE "$current_kernel_version|$meta_packages" | sort -V)

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
    echo "Removing old kernels: ${kernels_to_remove[*]}"
    sudo apt-get purge -y "${kernels_to_remove[@]}"
else
    echo "No old kernels to remove."
fi
