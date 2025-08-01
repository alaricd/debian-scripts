#!/usr/bin/env bash
set -e
script="$(dirname "$0")/../reboot-if-required.sh"

# positive: script checks for reboot-required file
if ! grep -q '/var/run/reboot-required' "$script"; then
  echo "Expected check for /var/run/reboot-required" >&2
  exit 1
fi

# negative: ensure script ends with fi
if ! tail -n 1 "$script" | grep -q '^fi$'; then
  echo "Script should end with fi" >&2
  exit 1
fi

echo "All tests passed."
