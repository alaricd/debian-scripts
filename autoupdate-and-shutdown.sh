#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin

# Logging function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] autoupdate-shutdown: $1" >&2
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
  log "ERROR: This script must be run as root"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

log "Starting system update and shutdown sequence"

log "Running system maintenance..."
"${SCRIPT_DIR}/check-if-already-updating.sh"
"${SCRIPT_DIR}/remove-old-kernels.sh"
"${SCRIPT_DIR}/remove-all-old-packages.sh"
"${SCRIPT_DIR}/remove-old-snaps.sh"
"${SCRIPT_DIR}/autoupdate.sh"

log "System maintenance completed, shutting down..."
shutdown -h now
