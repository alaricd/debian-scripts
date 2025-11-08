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

    # First pass: restart services that needrestart can handle automatically
    /usr/sbin/needrestart -r a

    # Check for active user sessions
    active_users=$(who | wc -l)
    active_sessions=$(loginctl list-sessions --no-legend 2>/dev/null | grep -v "lingering" | wc -l || echo "0")

    if [ "$active_users" -eq 0 ] && [ "$active_sessions" -eq 0 ]; then
      log "No active user sessions detected, safe to restart deferred services"

      # Get list of services that still need restart
      deferred_services=$(needrestart -b 2>/dev/null | grep -E '^NEEDRESTART-SVC:' | cut -d: -f2 || true)

      if [ -n "$deferred_services" ]; then
        log "Restarting deferred services:"
        echo "$deferred_services" | while read -r service; do
          if [ -n "$service" ]; then
            log "  Restarting ${service}..."
            systemctl restart "${service}" 2>&1 | sed "s/^/    /" || log "    Warning: Failed to restart ${service}"
          fi
        done
      fi
    else
      log "Active user sessions detected (users: $active_users, sessions: $active_sessions)"
      log "Skipping restart of critical services to avoid disrupting user sessions"

      # List what services are deferred
      deferred_services=$(needrestart -b 2>/dev/null | grep -E '^NEEDRESTART-SVC:' | cut -d: -f2 || true)
      if [ -n "$deferred_services" ]; then
        log "The following services need restart but are deferred:"
        echo "$deferred_services" | sed 's/^/  - /' >&2
      fi
    fi

    log "Service restart process completed"
  else
    log "needrestart not available, skipping service restart"
  fi
fi
