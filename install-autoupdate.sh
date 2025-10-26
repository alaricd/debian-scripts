#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

log() {
  printf '%s %s\n' "$(date -Is)" "$*"
}

err() {
  log "ERROR: $*" >&2
}

require_root() {
  if [[ $(id -u) -ne 0 ]]; then
    err "this installer must run as root; re-run with sudo or as root"
    exit 1
  fi
}

ensure_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    err "required command '$cmd' not found; install it and retry"
    exit 1
  fi
}

main() {
  require_root
  ensure_command install
  ensure_command apt-get

  local script_dir target_script service_unit timer_unit
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  target_script="/usr/local/sbin/autoupdate-and-reboot.sh"
  service_unit="/etc/systemd/system/autoupdate.service"
  timer_unit="/etc/systemd/system/autoupdate.timer"

  if [[ ! -f "$script_dir/autoupdate-and-reboot.sh" ]]; then
    err "autoupdate-and-reboot.sh not found alongside installer"
    exit 1
  fi
  if [[ ! -f "$script_dir/systemd/autoupdate.service" || ! -f "$script_dir/systemd/autoupdate.timer" ]]; then
    err "systemd units missing; run from repository root"
    exit 1
  fi

  log "installing autoupdate-and-reboot.sh to ${target_script}"
  install -Dm755 "$script_dir/autoupdate-and-reboot.sh" "$target_script"

  log "installing systemd units"
  install -Dm644 "$script_dir/systemd/autoupdate.service" "$service_unit"
  install -Dm644 "$script_dir/systemd/autoupdate.timer" "$timer_unit"

  if [[ ! -e /var/log/autoupdate.log ]]; then
    log "creating /var/log/autoupdate.log"
    touch /var/log/autoupdate.log
    if getent group adm >/dev/null 2>&1; then
      chown root:adm /var/log/autoupdate.log || true
    fi
    chmod 640 /var/log/autoupdate.log || true
  fi

  if command -v systemctl >/dev/null 2>&1; then
    log "reloading systemd units"
    systemctl daemon-reload

    log "enabling autoupdate.timer"
    systemctl enable --now autoupdate.timer

    log "disabling apt-daily-upgrade.timer to avoid lock contention"
    systemctl disable --now apt-daily-upgrade.timer || true
  else
    log "systemctl not detected; enable the service manually if needed"
  fi

  log "installation complete"
}

main "$@"
