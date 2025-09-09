#!/usr/bin/env bash
set -e
# Remove all old packages script with enhanced error handling

PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] remove-old-packages: $1" >&2
}

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]] && ! command -v sudo &> /dev/null; then
    log "ERROR: This script requires root privileges or sudo"
    exit 1
fi

# Check for required commands
for cmd in apt-get; do
    if ! command -v "$cmd" &> /dev/null; then
        log "ERROR: Required command '$cmd' not found"
        exit 1
    fi
done

log "Starting package cleanup process"

# Loop autoremove until no more packages are removed
log "Removing unnecessary packages..."
iteration=0
max_iterations=5

while [[ $iteration -lt $max_iterations ]]; do
    log "Running autoremove (iteration $((iteration + 1))/$max_iterations)..."
    output=$(sudo apt-get autoremove -y 2>&1)
    
    if echo "$output" | grep -q '0 upgraded, 0 newly installed, 0 to remove'; then
        log "No more packages to remove"
        break
    fi
    
    iteration=$((iteration + 1))
    
    if [[ $iteration -eq $max_iterations ]]; then
        log "WARNING: Reached maximum iterations, some packages may still be removable"
    fi
done

log "Package cleanup completed successfully"
