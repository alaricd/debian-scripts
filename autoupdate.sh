#!/usr/bin/env bash
set -e
PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin
export DEBIAN_FRONTEND=noninteractive

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] autoupdate: $1" >&2
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log "ERROR: This script must be run as root"
    exit 1
fi

# Check for required commands
for cmd in dpkg apt-get deborphan; do
    if ! command -v "$cmd" &> /dev/null; then
        log "ERROR: Required command '$cmd' not found"
        exit 1
    fi
done

log "Starting system update process"

log "Configuring packages..."
dpkg --configure -a --force-confdef --force-confold

log "Updating package lists..."
apt-get update

log "Upgrading system packages..."
apt-get dist-upgrade -y

log "Removing orphaned packages..."
orphaned_packages=$(deborphan --guess-all | grep -v "$(apt-mark showmanual)" | tr '\n' ' ')
if [[ -n "$orphaned_packages" ]]; then
    apt-get purge $orphaned_packages -y
else
    log "No orphaned packages found"
fi

log "Running requirements check..."
/bin/check-requirements.sh

log "System update completed successfully"
