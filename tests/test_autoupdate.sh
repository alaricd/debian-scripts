#!/usr/bin/env bash
set -e
script="$(dirname "$0")/../autoupdate.sh"

# positive: script calls remove-all-old-packages.sh
if ! grep -q "remove-all-old-packages.sh" "$script"; then
  echo "Expected call to remove-all-old-packages.sh" >&2
  exit 1
fi

# positive: script performs dist-upgrade
if ! grep -q "dist-upgrade" "$script"; then
  echo "Expected dist-upgrade command" >&2
  exit 1
fi

# negative: script should not reference deborphan
if grep -q deborphan "$script"; then
  echo "Script must not reference deborphan" >&2
  exit 1
fi

echo "All tests passed."
