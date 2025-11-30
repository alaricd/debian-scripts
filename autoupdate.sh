#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

if [[ "${DEBUG:-0}" == "1" ]]; then
  set -x
fi

PATH="${PATH:-/usr/bin:/bin:/usr/sbin:/sbin}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

log_default() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] autoupdate: $*" >&2
}

run_autoupdate() {
  local logger="${1:-log_default}"

  if ! command -v "$logger" >/dev/null 2>&1; then
    logger="log_default"
  fi

  if ! command -v apt-get >/dev/null 2>&1; then
    "$logger" "apt-get not found; cannot continue"
    return 1
  fi

  "$logger" "refreshing package lists"
  apt-get update -y

  "$logger" "calculating planned upgrades"
  if simulation_output="$(apt-get dist-upgrade -s)"; then
    PENDING_UPGRADES="$(printf '%s\n' "$simulation_output" | grep -c '^Inst ' || true)"
    "$logger" "planned upgrades: ${PENDING_UPGRADES}"
  else
    "$logger" "failed to simulate dist-upgrade"
    return 1
  fi

  "$logger" "applying dist-upgrade"
  apt-get dist-upgrade -y

  if command -v needrestart >/dev/null 2>&1; then
    "$logger" "restarting affected services via needrestart"
    if ! needrestart -r a; then
      "$logger" "needrestart reported failures"
      return 1
    fi
  fi

  "$logger" "running autoremove with purge"
  apt-get autoremove --purge -y
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  run_autoupdate
fi
