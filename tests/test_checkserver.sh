#!/usr/bin/env bash
set -e
script="$(dirname "$0")/../checkserver.sh"

# positive: script validates argument count
if ! grep -q "Usage" "$script"; then
  echo "Expected usage message" >&2
  exit 1
fi

# negative: script should not use unquoted positional parameters
if grep -q "nc -z \$1 \$2" "$script"; then
  echo "Script should quote positional parameters" >&2
  exit 1
fi

echo "All tests passed."
