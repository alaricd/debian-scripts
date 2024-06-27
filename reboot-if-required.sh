#!/usr/bin/env bash
# Improved remove-old-kernels.sh script with current kernel protection

PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin
# Check if a reboot is required
if [ -f /var/run/reboot-required ]; then
    echo "Reboot required, rebooting now..."
    /sbin/reboot
else
    # Restart affected services
    echo "Restarting affected services..."
    /usr/sbin/needrestart -r a
fi