#!/usr/bin/env bash
set -e
# Reboot if required script with enhanced logging

PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] reboot-if-required: $1" >&2
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log "ERROR: This script must be run as root"
    exit 1
fi

# Check for required commands
for cmd in needrestart reboot; do
    if ! command -v "$cmd" &> /dev/null; then
        log "WARNING: Command '$cmd' not found"
    fi
done

log "Checking reboot requirements..."

# Check if a reboot is required
if [ -f /var/run/reboot-required ]; then
    log "Reboot flag detected at /var/run/reboot-required"
    log "System reboot required, rebooting now..."
    /sbin/reboot
else
    log "No reboot flag detected, checking for service restarts..."
    if command -v needrestart &> /dev/null; then
        log "Restarting affected services automatically..."
        /usr/sbin/needrestart -r a
        log "Service restart process completed"
    else
        log "needrestart not available, skipping service restart"
    fi
fi