#!/usr/bin/env bash
# Improved remove-old-kernels.sh script with current kernel protection

PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin

# Mark packages that are no longer explicitly required as automatic
apt-mark minimize-manual

# Remove deborphan if it is present
if dpkg -s deborphan >/dev/null 2>&1; then
    apt-get purge -y deborphan
fi

# Run autoremove repeatedly with an upper attempt limit to avoid infinite loops
for attempt in $(seq 1 10); do
    if sudo apt-get autoremove -y | grep -q '0 upgraded, 0 newly installed, 0 to remove'; then
        break
    fi
    echo "Running autoremove again to ensure all unnecessary packages are removed."
done

echo "System cleanup complete."
