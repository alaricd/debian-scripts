#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PATH=/usr/sbin:/usr/bin:/sbin:/bin
LOGFILE=${LOGFILE:-/var/log/autoupdate.log}
LOCKFILE=${LOCKFILE:-/var/lock/autoupdate.lock}
export DEBIAN_FRONTEND=noninteractive

APT_COMMON_OPTS=(-o Acquire::Retries=3 -o Acquire::http::Timeout=20 -o Dpkg::Options::=--force-confold)
APT_RUN_OPTS=(${APT_COMMON_OPTS[@]} -y)
APT_SIM_OPTS=(${APT_COMMON_OPTS[@]} -s)

# Ensure log file exists before tee attempts to append
if [[ ! -e "$LOGFILE" ]]; then
  touch "$LOGFILE"
  chmod 640 "$LOGFILE" || true
fi

log() {
  local timestamp message line
  timestamp="$(date -Is)"
  message="$*"
  line="$timestamp $message"
  printf '%s\n' "$line" | tee -a "$LOGFILE"
  if command -v logger >/dev/null 2>&1; then
    printf '%s\n' "$line" | logger -t autoupdate
  fi
}

trap 'rc=$?; log "autoupdate: error on line ${LINENO} (exit ${rc})"; exit ${rc}' ERR

exec 9>"$LOCKFILE"
if ! flock -n 9; then
  log "autoupdate: another instance is running; exiting"
  exit 0
fi

run_with_retry() {
  local description="$1"
  local attempts="$2"
  local initial_delay="$3"
  shift 3
  local attempt delay status
  delay="$initial_delay"
  for ((attempt = 1; attempt <= attempts; attempt++)); do
    if "$@"; then
      return 0
    fi
    status=$?
    if (( attempt == attempts )); then
      log "$description failed after ${attempts} attempts (exit ${status})"
      return $status
    fi
    log "$description attempt ${attempt} failed (exit ${status}); retrying in ${delay}s"
    sleep "$delay"
    delay=$((delay * 2))
  done
}

is_container() {
  if command -v systemd-detect-virt >/dev/null 2>&1; then
    systemd-detect-virt -cq && return 0
  fi
  grep -qE '/(lxc|docker)/' /proc/1/cgroup 2>/dev/null
}

active_tty_sessions() {
  if who | grep -qE '\bpts/|tty'; then
    return 0
  fi
  return 1
}

log "autoupdate: start"

run_with_retry "apt-get update" 3 5 apt-get "${APT_COMMON_OPTS[@]}" update

UPG_CNT=$(apt-get "${APT_SIM_OPTS[@]}" dist-upgrade | grep -c '^Inst ' || true)
log "planned upgrades: ${UPG_CNT}"

run_with_retry "apt-get dist-upgrade" 3 10 apt-get "${APT_RUN_OPTS[@]}" dist-upgrade

if command -v needrestart >/dev/null 2>&1; then
  log "needrestart: attempting service restarts"
  NEEDRESTART_MODE=a needrestart -r a || log "needrestart reported non-zero exit"
fi

log "running autoremove"
run_with_retry "apt-get autoremove" 3 10 apt-get "${APT_RUN_OPTS[@]}" autoremove --purge

PENDING=$(apt-get "${APT_SIM_OPTS[@]}" dist-upgrade | grep -c '^Inst ' || true)
REQ=0
if [[ -f /var/run/reboot-required ]]; then
  REQ=1
fi
if [[ "${REBOOT_FORCE:-0}" == "1" ]]; then
  REQ=1
fi
log "status uname=$(uname -r) pending=${PENDING} reboot_required=${REQ}"

if (( REQ == 1 )); then
  if is_container; then
    log "container detected; skip reboot"
    exit 0
  fi
  if active_tty_sessions; then
    log "active tty session detected; skipping reboot"
    exit 0
  fi
  if [[ "${NO_REBOOT:-0}" == "1" ]]; then
    log "NO_REBOOT=1 set; skipping reboot"
    exit 0
  fi
  log "rebooting now"
  /sbin/reboot
else
  log "no reboot required"
fi
