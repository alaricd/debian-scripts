#!/usr/bin/env bash
set -e
PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] autoupdate-reboot: $1" >&2
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log "ERROR: This script must be run as root"
    exit 1
fi

log "Starting system update and reboot sequence"

if [ -n "$1" ]; then
    log "Forcing reboot requirement"
    touch /var/run/reboot-required
fi
log "Running system maintenance sequence..."
/bin/check-if-already-updating.sh
/bin/remove-old-kernels.sh
/bin/remove-all-old-packages.sh
/bin/remove-old-snaps.sh
/bin/autoupdate.sh

log "System maintenance completed, checking reboot requirements..."
/bin/reboot-if-required.sh