#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Logging function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] checkserver: $1" >&2
}

# Input validation
if [[ $# -ne 2 ]]; then
  log "ERROR: Usage: $0 <host> <port>"
  exit 1
fi

# Check for required commands
if ! command -v nc &> /dev/null; then
  log "ERROR: netcat (nc) command not found"
  exit 1
fi

host="$1"
port="$2"

# Validate port is numeric
if ! [[ "$port" =~ ^[0-9]+$ ]]; then
  log "ERROR: Port must be numeric"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

log "Checking connectivity to $host:$port..."
if ! nc -z "$host" "$port"; then
  log "Server $host:$port is not accessible, triggering update and reboot"
  "${SCRIPT_DIR}/autoupdate-and-reboot.sh"
else
  log "Server $host:$port is accessible"
fi
