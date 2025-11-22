#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(mktemp -d)"
  STATE_DIR="$TEST_ROOT/state"
  mkdir -p "$STATE_DIR"
  export CLEANSHUTDOWN_STATE_DIR="$STATE_DIR"

  STUB_BIN="$TEST_ROOT/bin"
  mkdir -p "$STUB_BIN"
  export PATH="$STUB_BIN"

  ln -s "$BATS_TEST_DIRNAME/../cleanshutdown" "$TEST_ROOT/cleanshutdown"

  for helper in \
    check-if-already-updating.sh \
    remove-old-kernels.sh \
    remove-all-old-packages.sh \
    remove-old-snaps.sh \
    autoupdate-and-reboot.sh; do
    cat <<'STUB' >"$TEST_ROOT/$helper"
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$(basename "$0")" >> "${CLEANSHUTDOWN_STATE_DIR}/order.log"
STUB
    chmod +x "$TEST_ROOT/$helper"
  done

  cat <<'STUB' >"$TEST_ROOT/autoupdate-and-reboot.sh"
#!/usr/bin/env bash
set -euo pipefail
if [[ "${NO_REBOOT:-}" != "1" ]]; then
  printf 'missing NO_REBOOT\n' >> "${CLEANSHUTDOWN_STATE_DIR}/errors.log"
  exit 1
fi
printf '%s\n' "$(basename "$0")" >> "${CLEANSHUTDOWN_STATE_DIR}/order.log"
STUB
  chmod +x "$TEST_ROOT/autoupdate-and-reboot.sh"

  cat <<'STUB' >"$STUB_BIN/sync"
#!/usr/bin/env bash
set -euo pipefail
printf 'sync %s\n' "$*" >> "${CLEANSHUTDOWN_STATE_DIR}/commands.log"
STUB
  chmod +x "$STUB_BIN/sync"

  cat <<'STUB' >"$STUB_BIN/shutdown"
#!/usr/bin/env bash
set -euo pipefail
printf 'shutdown %s\n' "$*" >> "${CLEANSHUTDOWN_STATE_DIR}/commands.log"
STUB
  chmod +x "$STUB_BIN/shutdown"

  cat <<'STUB' >"$STUB_BIN/sudo"
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == "-u" ]]; then
  target="$2"
  shift 2
  CLEANSHUTDOWN_TEST_ROLE="sudo-${target}" "$@"
else
  CLEANSHUTDOWN_TEST_ROLE="sudo" "$@"
fi
STUB
  chmod +x "$STUB_BIN/sudo"

  cat <<'STUB' >"$STUB_BIN/bleachbit"
#!/usr/bin/env bash
set -euo pipefail
role="${CLEANSHUTDOWN_TEST_ROLE:-root}"
printf 'bleachbit role=%s args=%s\n' "$role" "$*" >> "${CLEANSHUTDOWN_STATE_DIR}/commands.log"
STUB
  chmod +x "$STUB_BIN/bleachbit"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

@test "cleanshutdown orchestrates maintenance and shutdown with bleachbit" {
  run CLEANSHUTDOWN_ALLOW_NONROOT=1 SUDO_USER=tester "$TEST_ROOT/cleanshutdown"
  [ "$status" -eq 0 ]
  run cat "$CLEANSHUTDOWN_STATE_DIR/order.log"
  [ "$status" -eq 0 ]
  mapfile -t order < "$CLEANSHUTDOWN_STATE_DIR/order.log"
  [ "${order[0]}" = "check-if-already-updating.sh" ]
  [ "${order[1]}" = "remove-old-kernels.sh" ]
  [ "${order[2]}" = "remove-all-old-packages.sh" ]
  [ "${order[3]}" = "remove-old-snaps.sh" ]
  [ "${order[4]}" = "autoupdate-and-reboot.sh" ]

  run cat "$CLEANSHUTDOWN_STATE_DIR/commands.log"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bleachbit role=sudo-tester args=-c --preset"* ]]
  [[ "$output" == *"bleachbit role=root args=-c --preset"* ]]
  [[ "$output" == *"shutdown -h now"* ]]
}
