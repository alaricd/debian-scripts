#!/usr/bin/env bash
set -e
script="$(dirname "$0")/../remove-all-old-packages.sh"

# positive: script runs apt-mark minimize-manual
if ! grep -q "apt-mark minimize-manual" "$script"; then
  echo "Expected apt-mark minimize-manual step" >&2
  exit 1
fi

# positive: script loops up to 10 times using a for loop with seq
if ! grep -q "for attempt in \$(seq 1 10)" "$script"; then
  echo "Expected for loop with seq limit" >&2
  exit 1
fi

# positive: script invokes apt-get autoremove
if ! grep -q "apt-get autoremove" "$script"; then
  echo "Expected apt-get autoremove command" >&2
  exit 1
fi

# negative: script should not use a while loop for autoremove
if grep -q "while .*apt-get autoremove" "$script"; then
  echo "Should not use while loop for autoremove" >&2
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
