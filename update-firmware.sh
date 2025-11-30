#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PATH="${PATH:-/usr/bin:/bin:/usr/sbin:/sbin}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

# Logging function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] update-firmware: $1" >&2
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
  log "ERROR: This script must be run as root"
  exit 1
fi

# Check if fwupdmgr is available
if ! command -v fwupdmgr >/dev/null 2>&1; then
  log "fwupdmgr not found - firmware updates will be skipped"
  exit 0
fi

log "Starting firmware update process"

# Refresh firmware metadata
log "Refreshing firmware metadata..."
if ! fwupdmgr refresh --force 2>&1 | tee >(cat >&2); then
  log "WARNING: Failed to refresh firmware metadata, continuing anyway"
fi

# Get available updates
log "Checking for firmware updates..."
if fwupdmgr get-updates 2>&1 | tee >(cat >&2) | grep -q "No updates available"; then
  log "No firmware updates available"
  exit 0
fi

# Install firmware updates non-interactively
log "Installing firmware updates..."
if fwupdmgr update -y 2>&1 | tee >(cat >&2); then
  log "Firmware updates completed successfully"
else
  log "WARNING: Some firmware updates may have failed"
  exit 0
fi

log "Firmware update process completed"
