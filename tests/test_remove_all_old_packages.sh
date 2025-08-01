#!/usr/bin/env bash
set -e
script="$(dirname "$0")/../remove-all-old-packages.sh"

# positive: script runs apt-mark minimize-manual
if ! grep -q "apt-mark minimize-manual" "$script"; then
  echo "Expected apt-mark minimize-manual step" >&2
  exit 1
fi

# positive: script loops over apt-get autoremove
if ! grep -q "apt-get autoremove" "$script"; then
  echo "Expected apt-get autoremove command" >&2
  exit 1
fi

# positive: script purges deborphan if installed
if ! grep -q "purge -y deborphan" "$script"; then
  echo "Expected deborphan purge command" >&2
  exit 1
fi

# negative: script should not call apt-get dist-upgrade
if grep -q "dist-upgrade" "$script"; then
  echo "Script should not run dist-upgrade" >&2
  exit 1
fi

echo "All tests passed."
