#!/usr/bin/env bash
set -e
script="$(dirname "$0")/../check-if-already-updating.sh"

# positive: script exits with code 1 when apt-get is running
if ! grep -q "exit 1" "$script"; then
  echo "Expected script to exit with status 1 when update is running" >&2
  exit 1
fi

# negative: ensure script closes with fi
if ! tail -n 1 "$script" | grep -q '^fi$'; then
  echo "Script should end with fi" >&2
  exit 1
fi

echo "All tests passed."
