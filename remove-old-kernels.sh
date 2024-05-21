#!/usr/bin/env bash
# Improved remove-old-kernels.sh script with current kernel protection

PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin

# Get the version and package of the currently running kernel
current_kernel_version=$(uname -r)
current_kernel_package=$(dpkg -l | grep linux-image | awk '{print $2}' | grep "$current_kernel_version")

# Get a list of installed kernels, excluding the current one
installed_kernels=$(dpkg --list | grep linux-image | awk '{print $2}' | grep -v "$current_kernel_version" | sort -V)

# Get the list of kernels that are older than the current kernel
kernels_to_remove=()
for kernel in $installed_kernels; do
    if dpkg --compare-versions "$kernel" lt "$current_kernel_version" && [ "$kernel" != "$current_kernel_package" ]; then
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

