#!/usr/bin/env bats

setup() {
  TEST_DIR="$(mktemp -d)"
  export AUTOTEST_STATE_DIR="$TEST_DIR/state"
  mkdir -p "$AUTOTEST_STATE_DIR"

  STUB_DIR="$TEST_DIR/bin"
  mkdir -p "$STUB_DIR"
  export PATH="$STUB_DIR:$PATH"
  export LOGFILE="$TEST_DIR/autoupdate.log"
  export LOCKFILE="$TEST_DIR/autoupdate.lock"

  cat <<'STUB' > "$STUB_DIR/apt-get"
#!/usr/bin/env bash
set -euo pipefail
state_dir="${AUTOTEST_STATE_DIR:?}"
mkdir -p "$state_dir"
echo "apt-get $*" >> "$state_dir/calls.log"

simulate=0
last_arg=""
for arg in "$@"; do
  [[ "$arg" == "-s" ]] && simulate=1
  if [[ "$arg" != -* ]]; then
    last_arg="$arg"
  fi
done

case "$last_arg" in
  update)
    exit 0
    ;;
  dist-upgrade)
    if (( simulate )); then
      count_file="$state_dir/sim_count"
      count=0
      [[ -f "$count_file" ]] && count="$(<"$count_file")"
      if (( count == 0 )); then
        printf 'Inst pkg1\nInst pkg2\n'
      fi
      printf '%s' "$((count + 1))" >"$count_file"
    else
      printf 'dist-upgrade\n' >> "$state_dir/order.log"
    fi
    exit 0
    ;;
  autoremove)
    printf 'autoremove\n' >> "$state_dir/order.log"
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
STUB
  chmod +x "$STUB_DIR/apt-get"

  cat <<'STUB' > "$STUB_DIR/logger"
#!/usr/bin/env bash
set -euo pipefail
cat >/dev/null
STUB
  chmod +x "$STUB_DIR/logger"

  cat <<'STUB' > "$STUB_DIR/systemd-detect-virt"
#!/usr/bin/env bash
set -euo pipefail
exit 1
STUB
  chmod +x "$STUB_DIR/systemd-detect-virt"

  cat <<'STUB' > "$STUB_DIR/who"
#!/usr/bin/env bash
set -euo pipefail
if [[ "${AUTOTEST_TTY_ACTIVE:-0}" == "1" ]]; then
  printf 'user pts/0 2023-01-01 00:00 (:0)\n'
else
  exit 0
fi
STUB
  chmod +x "$STUB_DIR/who"

  cat <<'STUB' > "$STUB_DIR/needrestart"
#!/usr/bin/env bash
set -euo pipefail
state_dir="${AUTOTEST_STATE_DIR:?}"
printf 'needrestart\n' >> "$state_dir/order.log"
if [[ "${AUTOTEST_NEEDRESTART_FAIL:-0}" == "1" ]]; then
  exit 1
fi
exit 0
STUB
  chmod +x "$STUB_DIR/needrestart"

  cat <<'STUB' > "$STUB_DIR/reboot"
#!/usr/bin/env bash
set -euo pipefail
state_dir="${AUTOTEST_STATE_DIR:?}"
printf 'reboot\n' >> "$state_dir/reboot.log"
exit 0
STUB
  chmod +x "$STUB_DIR/reboot"

  cat <<'STUB' > "$STUB_DIR/dpkg-query"
#!/usr/bin/env bash
set -euo pipefail
# Stub for dpkg-query used by remove-old-kernels.sh
exit 0
STUB
  chmod +x "$STUB_DIR/dpkg-query"

  cat <<'STUB' > "$STUB_DIR/apt-mark"
#!/usr/bin/env bash
set -euo pipefail
# Stub for apt-mark used by remove-all-old-packages.sh
printf 'Canceled marking change.\n'
exit 0
STUB
  chmod +x "$STUB_DIR/apt-mark"

  cat <<'STUB' > "$STUB_DIR/snap"
#!/usr/bin/env bash
set -euo pipefail
# Stub for snap used by remove-old-snaps.sh
exit 0
STUB
  chmod +x "$STUB_DIR/snap"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "script enables strict mode" {
  grep -q 'set -Eeuo pipefail' autoupdate-and-reboot.sh
}

@test "logs planned upgrade count" {
  run ./autoupdate-and-reboot.sh
  [ "$status" -eq 0 ]
  grep -q 'planned upgrades: 2' "$LOGFILE"
}

@test "autoremove runs after dist-upgrade" {
  run ./autoupdate-and-reboot.sh
  [ "$status" -eq 0 ]
  [ -f "$AUTOTEST_STATE_DIR/order.log" ]
  mapfile -t entries < "$AUTOTEST_STATE_DIR/order.log"
  local dist_index=-1
  local autoremove_index=-1
  for i in "${!entries[@]}"; do
    case "${entries[$i]}" in
      dist-upgrade)
        dist_index="$i"
        ;;
      autoremove)
        autoremove_index="$i"
        ;;
    esac
  done
  (( dist_index >= 0 ))
  (( autoremove_index >= 0 ))
  (( dist_index < autoremove_index ))
}

@test "no reboot when no requirement" {
  run ./autoupdate-and-reboot.sh
  [ "$status" -eq 0 ]
  [ ! -f "$AUTOTEST_STATE_DIR/reboot.log" ]
}

@test "honors NO_REBOOT when forced" {
  run env NO_REBOOT=1 REBOOT_FORCE=1 ./autoupdate-and-reboot.sh
  [ "$status" -eq 0 ]
  [ ! -f "$AUTOTEST_STATE_DIR/reboot.log" ]
}

@test "final status line includes reboot flag" {
  run ./autoupdate-and-reboot.sh
  [ "$status" -eq 0 ]
  grep -q 'status uname=' "$LOGFILE"
  grep -q 'reboot_required=' "$LOGFILE"
}
