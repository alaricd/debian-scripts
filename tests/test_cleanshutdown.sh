#!/usr/bin/env bash
set -e

script="$(dirname "$0")/../cleanshutdown"

# positive test: script references check-if-already-updating.sh using
# the SCRIPT_DIR variable so that it works from a user directory.
if ! grep -q "\${SCRIPT_DIR}/check-if-already-updating.sh" "$script"; then
  echo "Expected script to reference check-if-already-updating.sh with SCRIPT_DIR" >&2
  exit 1
fi

# positive test: ensure SCRIPT_DIR variable is defined
if ! grep -q "SCRIPT_DIR=\"\$(cd \"\$(dirname \"\$0\")\" && pwd)\"" "$script"; then
  echo "Expected SCRIPT_DIR variable definition" >&2
  exit 1
fi


# negative test: script should not reference check-if-already-running.sh
if grep -q "check-if-already-running.sh" "$script"; then
  echo "Script incorrectly references check-if-already-running.sh" >&2
  exit 1
fi

# negative test: script should not hard-code /bin paths
if grep -q "/bin/check-if-already-updating.sh" "$script"; then
  echo "Script should not use absolute /bin path" >&2
  exit 1
fi

# positive test: BleachBit commands ignore failures
if ! grep -q 'sudo -u "\${USER}" /usr/bin/bleachbit -c --preset || true' "$script"; then
  echo "BleachBit user command must ignore failures" >&2
  exit 1
fi

if ! grep -q '/usr/bin/bleachbit -c --preset || true' "$script"; then
  echo "BleachBit root command must ignore failures" >&2
  exit 1
fi

# negative test: BleachBit lines should not be chained with &&
if grep -q 'bleachbit -c --preset &&' "$script"; then
  echo "BleachBit commands should not use &&" >&2
  exit 1
fi

# negative test: autoupdate should not be chained with && to BleachBit
if grep -q 'autoupdate.sh" &&' "$script"; then
  echo "autoupdate.sh should not chain to BleachBit" >&2
  exit 1
fi

echo "All tests passed."
