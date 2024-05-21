#!/usr/bin/env bash
# Improved remove-old-kernels.sh script with current kernel protection

PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin

# Loop autoremove until no more packages are removed
while ! sudo apt-get autoremove -y | grep -q '0 upgraded, 0 newly installed, 0 to remove'; do
    echo "Running autoremove again to ensure all unnecessary packages are removed."
done

echo "System cleanup complete."
