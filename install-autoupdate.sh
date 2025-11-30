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

  local script_dir target_dir service_unit timer_unit
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  target_dir="/usr/local/sbin"
  service_unit="/etc/systemd/system/autoupdate.service"
  timer_unit="/etc/systemd/system/autoupdate.timer"

  # List of required scripts
  local required_scripts=(
    "autoupdate-and-reboot.sh"
    "autoupdate-and-shutdown.sh"
    "autoupdate.sh"
    "check-if-already-updating.sh"
    "remove-old-kernels.sh"
    "remove-old-snaps.sh"
    "remove-all-old-packages.sh"
    "reboot-if-required.sh"
    "check-requirements.sh"
    "update-firmware.sh"
  )

  # Verify all required scripts exist
  for script in "${required_scripts[@]}"; do
    if [[ ! -f "$script_dir/$script" ]]; then
      err "$script not found in $script_dir"
      exit 1
    fi
  done

  if [[ ! -f "$script_dir/systemd/autoupdate.service" || ! -f "$script_dir/systemd/autoupdate.timer" ]]; then
    err "systemd units missing; run from repository root"
    exit 1
  fi

  # Stop services before updating files
  if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet autoupdate.timer; then
      log "stopping autoupdate.timer before update"
      systemctl stop autoupdate.timer
    fi
    if systemctl is-active --quiet autoupdate.service; then
      log "stopping autoupdate.service before update"
      systemctl stop autoupdate.service
    fi
  fi

  log "installing scripts to ${target_dir}"
  for script in "${required_scripts[@]}"; do
    log "  installing $script"
    install -Dm755 "$script_dir/$script" "$target_dir/$script"
  done

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

    log "enabling and starting autoupdate.timer with updated files"
    systemctl enable autoupdate.timer
    systemctl start autoupdate.timer

    log "disabling apt-daily-upgrade.timer to avoid lock contention"
    systemctl disable --now apt-daily-upgrade.timer || true
  else
    log "systemctl not detected; enable the service manually if needed"
  fi

  log "installation complete"
}

main "$@"
