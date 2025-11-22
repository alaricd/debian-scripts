#!/usr/bin/env bats

setup() {
  TEST_DIR="$(mktemp -d)"
  AUTOTEST_STATE_DIR="$TEST_DIR/state"
  mkdir -p "$AUTOTEST_STATE_DIR"
  export AUTOTEST_STATE_DIR

  STUB_DIR="$TEST_DIR/bin"
  mkdir -p "$STUB_DIR"
  export PATH="$STUB_DIR:$PATH"

  cat <<'STUB' >"$STUB_DIR/uname"
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "-r" ]]; then
  printf '6.1.0-18-amd64\n'
  exit 0
fi
exec /usr/bin/uname "$@"
STUB
  chmod +x "$STUB_DIR/uname"

  cat <<'STUB' >"$STUB_DIR/dpkg-query"
#!/usr/bin/env bash
set -euo pipefail

scenario="${AUTOTEST_SCENARIO:-remove_one}"

if [[ "${1:-}" != "-W" ]]; then
  printf 'unexpected dpkg-query usage: %s\n' "$*" >&2
  exit 1
fi

case "${2:-}" in
  "-f=\${Status}\\n")
    case "$scenario" in
      remove_one|keep_newer)
        if [[ "${3:-}" == "linux-image-6.1.0-18-amd64" ]]; then
          printf 'install ok installed\n'
          exit 0
        fi
        ;;
      unsigned_current)
        if [[ "${3:-}" == "linux-image-unsigned-6.1.0-18-generic" ]]; then
          printf 'install ok installed\n'
          exit 0
        fi
        ;;
    esac
    exit 1
    ;;
  "-f=\${Version}")
    case "$scenario" in
      remove_one|keep_newer)
        if [[ "${3:-}" == "linux-image-6.1.0-18-amd64" ]]; then
          printf '6.1.76-1\n'
          exit 0
        fi
        ;;
      unsigned_current)
        if [[ "${3:-}" == "linux-image-unsigned-6.1.0-18-generic" ]]; then
          printf '6.1.76-1\n'
          exit 0
        fi
        ;;
    esac
    exit 1
    ;;
  "-f=\${Package} \${Version}\\n")
    case "$scenario" in
      remove_one)
        printf 'linux-image-6.1.0-17-amd64 6.1.52-1\n'
        printf 'linux-image-6.1.0-18-amd64 6.1.76-1\n'
        printf 'linux-image-6.1.0-19-amd64 6.1.85-1\n'
        ;;
      keep_newer)
        printf 'linux-image-6.1.0-18-amd64 6.1.76-1\n'
        printf 'linux-image-6.1.0-19-amd64 6.1.85-1\n'
        ;;
      unsigned_current)
        printf 'linux-image-unsigned-6.1.0-17-generic 6.1.52-1\n'
        printf 'linux-image-unsigned-6.1.0-18-generic 6.1.76-1\n'
        printf 'linux-image-unsigned-6.1.0-19-generic 6.1.85-1\n'
        ;;
    esac
    exit 0
    ;;
esac

printf 'unexpected dpkg-query usage: %s\n' "$*" >&2
exit 1
STUB
  chmod +x "$STUB_DIR/dpkg-query"

  cat <<'STUB' >"$STUB_DIR/apt-get"
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "${AUTOTEST_STATE_DIR:?}/apt-get.log"
STUB
  chmod +x "$STUB_DIR/apt-get"

  cat <<'STUB' >"$STUB_DIR/sudo"
#!/usr/bin/env bash
set -euo pipefail
exec "$@"
STUB
  chmod +x "$STUB_DIR/sudo"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "purges kernels older than the running kernel package" {
  run AUTOTEST_SCENARIO=remove_one ./remove-old-kernels.sh
  [ "$status" -eq 0 ]
  run cat "$AUTOTEST_STATE_DIR/apt-get.log"
  [ "$status" -eq 0 ]
  [[ "$output" == *"purge -y linux-image-6.1.0-17-amd64"* ]]
}

@test "does not purge kernels that are current or newer" {
  run AUTOTEST_SCENARIO=keep_newer ./remove-old-kernels.sh
  [ "$status" -eq 0 ]
  [ ! -f "$AUTOTEST_STATE_DIR/apt-get.log" ]
}

@test "handles unsigned kernel packages" {
  run AUTOTEST_SCENARIO=unsigned_current ./remove-old-kernels.sh
  [ "$status" -eq 0 ]
  run cat "$AUTOTEST_STATE_DIR/apt-get.log"
  [ "$status" -eq 0 ]
  [[ "$output" == *"purge -y linux-image-unsigned-6.1.0-17-generic"* ]]
  [[ "$output" != *"linux-image-unsigned-6.1.0-18-generic"* ]]
}
