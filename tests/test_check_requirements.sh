#!/usr/bin/env bash
set -e
script="$(dirname "$0")/../check-requirements.sh"

# positive: uses a case statement for distro detection
if ! grep -q "case \"\$ID\"" "$script"; then
  echo "Expected case statement for distro detection" >&2
  exit 1
fi

# positive: script purges deborphan if present
if ! grep -q "purge -y deborphan" "$script"; then
  echo "Expected deborphan purge step" >&2
  exit 1
fi

# negative: script should not attempt to install deborphan
if grep -q "apt-cache show deborphan" "$script"; then
  echo "Script should not install deborphan" >&2
  exit 1
fi

# negative: script must handle unsupported distributions
if ! grep -q "Unsupported distribution" "$script"; then
  echo "Expected unsupported distribution handler" >&2
  exit 1
fi

echo "All tests passed."
