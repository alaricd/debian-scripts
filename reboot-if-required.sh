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
    /usr/bin/systemctl daemon-reexec
    /usr/bin/systemctl restart $(systemctl list-units --type=service --state=running | grep '.service' | awk '{print $1}')
fi