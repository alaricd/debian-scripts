#!/usr/bin/env bash
set -e
script="$(dirname "$0")/../checkserver.sh"

# positive: script validates argument count
if ! grep -q "Usage" "$script"; then
  echo "Expected usage message" >&2
  exit 1
fi

# positive: script defines SCRIPT_DIR and uses it when calling autoupdate
if ! grep -q 'SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"' "$script"; then
  echo "Expected SCRIPT_DIR variable" >&2
  exit 1
fi
if ! grep -q '\${SCRIPT_DIR}/autoupdate-and-reboot.sh' "$script"; then
  echo "Expected SCRIPT_DIR usage for autoupdate-and-reboot.sh" >&2
  exit 1
fi

# negative: script should not use unquoted positional parameters
if grep -q "nc -z \$1 \$2" "$script"; then
  echo "Script should quote positional parameters" >&2
  exit 1
fi

# negative: script should not use hard-coded /bin path
if grep -q '/bin/autoupdate-and-reboot.sh' "$script"; then
  echo "Script should not use absolute /bin path" >&2
  exit 1
fi

echo "All tests passed."
