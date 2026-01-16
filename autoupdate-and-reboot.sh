#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

if [[ "${DEBUG:-0}" == "1" ]]; then
  set -x
fi

PATH="${PATH:-/usr/bin:/bin:/usr/sbin:/sbin}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

LOGFILE="${LOGFILE:-/var/log/autoupdate.log}"
LOCKFILE="${LOCKFILE:-/var/lock/autoupdate.lock}"
REBOOT_REQUIRED_FILE="${REBOOT_REQUIRED_FILE:-/var/run/reboot-required}"

# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/autoupdate.sh"

force_reboot=0

# If any argument is provided, treat it as a request to force a reboot flag
if [[ $# -gt 0 ]]; then
  force_reboot=1
  mkdir -p "$(dirname "$REBOOT_REQUIRED_FILE")"
  touch "$REBOOT_REQUIRED_FILE"
fi

if [[ "${REBOOT_FORCE:-0}" == "1" ]]; then
  force_reboot=1
fi

mkdir -p "$(dirname "$LOGFILE")" "$(dirname "$LOCKFILE")"
touch "$LOGFILE"
exec 3>>"$LOGFILE"

log() {
  local timestamp message
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  message="[$timestamp] autoupdate: $*"
  echo "$message" >&3
  if command -v logger >/dev/null 2>&1; then
    logger -t autoupdate "$message" || true
  fi
}

exec 9>"$LOCKFILE"
if ! flock -n 9; then
  log "another autoupdate run is already in progress; exiting"
  exit 0
fi

pending_upgrades=0
reboot_required=0

log "checking requirements"
"${SCRIPT_DIR}/check-requirements.sh"

log "removing old kernels"
"${SCRIPT_DIR}/remove-old-kernels.sh"

log "removing old snaps"
"${SCRIPT_DIR}/remove-old-snaps.sh"

log "starting system update"

run_autoupdate log
pending_upgrades="${PENDING_UPGRADES:-0}"
if [[ "${NEEDRESTART_FAILED:-0}" == "1" ]]; then
  reboot_required=1
fi

log "removing old packages"
"${SCRIPT_DIR}/remove-all-old-packages.sh"

if [ -f "$REBOOT_REQUIRED_FILE" ] || [[ "$force_reboot" == "1" ]]; then
  reboot_required=1
fi

log "status uname=$(uname -srm) pending=${pending_upgrades} reboot_required=${reboot_required}"

if [[ "$reboot_required" == "1" ]]; then
  if [[ "$force_reboot" == "0" ]]; then
    if [[ "${NO_REBOOT:-0}" == "1" ]]; then
      log "reboot required but suppressed by NO_REBOOT=1"
      exit 0
    fi

    if command -v systemd-detect-virt >/dev/null 2>&1 && systemd-detect-virt --quiet; then
      log "reboot required but running inside a container; skipping reboot"
      exit 0
    fi

    if who >/dev/null 2>&1 && [[ -n "$(who)" ]]; then
      log "active user sessions detected; skipping reboot"
      exit 0
    fi
  else
    log "reboot forced; bypassing safety checks"
  fi

  log "reboot required; rebooting now"
  reboot
else
  log "no reboot required"
fi
