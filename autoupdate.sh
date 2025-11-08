#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

log "Starting system update process"

log "Configuring packages..."
dpkg --configure -a --force-confdef --force-confold

log "Updating package lists..."
apt-get update -y

log "Upgrading system packages..."
apt-get dist-upgrade -y

log "Autoremoving unused packages..."
apt-get autoremove --purge -y

log "Updating firmware..."
"${SCRIPT_DIR}/update-firmware.sh"

log "Removing old packages..."
"${SCRIPT_DIR}/remove-all-old-packages.sh"

log "Running requirements check..."
"${SCRIPT_DIR}/check-requirements.sh"

log "System update completed successfully"
