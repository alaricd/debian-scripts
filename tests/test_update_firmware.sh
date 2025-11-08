#!/usr/bin/env bash
set -e

script="$(dirname "$0")/../update-firmware.sh"

# positive test: script checks if fwupdmgr is available
if ! grep -q 'command -v fwupdmgr' "$script"; then
  echo "Expected check for fwupdmgr command" >&2
  exit 1
fi

# positive test: script refreshes firmware metadata
if ! grep -q 'fwupdmgr refresh' "$script"; then
  echo "Expected firmware metadata refresh command" >&2
  exit 1
fi

# positive test: script checks for available updates
if ! grep -q 'fwupdmgr get-updates' "$script"; then
  echo "Expected firmware update check command" >&2
  exit 1
fi

# positive test: script installs firmware updates non-interactively
if ! grep -q 'fwupdmgr update -y' "$script"; then
  echo "Expected non-interactive firmware update command" >&2
  exit 1
fi

# positive test: script exits gracefully when fwupdmgr not found
if ! grep -q 'exit 0' "$script"; then
  echo "Expected graceful exit when fwupdmgr not found" >&2
  exit 1
fi

# positive test: script has proper logging
if ! grep -q 'log()' "$script"; then
  echo "Expected logging function" >&2
  exit 1
fi

# positive test: script checks for root privileges
if ! grep -q 'EUID -ne 0' "$script"; then
  echo "Expected root privilege check" >&2
  exit 1
fi

# negative test: script should not run fwupdmgr interactively
if grep -q 'fwupdmgr update[^-]' "$script" | grep -v 'fwupdmgr update -y'; then
  echo "Script should not run fwupdmgr interactively" >&2
  exit 1
fi

echo "All tests passed."
