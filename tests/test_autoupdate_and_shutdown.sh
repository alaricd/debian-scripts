#!/usr/bin/env bash
set -e
script="$(dirname "$0")/../autoupdate-and-shutdown.sh"

# positive: script defines SCRIPT_DIR variable
if ! grep -q 'SCRIPT_DIR=' "$script"; then
  echo "Expected SCRIPT_DIR variable" >&2
  exit 1
fi

# positive: uses SCRIPT_DIR when calling remove-old-snaps.sh
if ! grep -q "\${SCRIPT_DIR}/remove-old-snaps.sh" "$script"; then
  echo "Expected SCRIPT_DIR usage for remove-old-snaps.sh" >&2
  exit 1
fi

# positive: script calls autoupdate.sh via SCRIPT_DIR
if ! grep -q "\${SCRIPT_DIR}/autoupdate.sh" "$script"; then
  echo "Expected call to autoupdate.sh" >&2
  exit 1
fi

# negative: script should not use hard-coded /bin path
if grep -q '/bin/remove-old-snaps.sh' "$script"; then
  echo "Script should not use absolute /bin path" >&2
  exit 1
fi

# negative: script should not call remove-all-old-packages.sh
if grep -q 'remove-all-old-packages.sh' "$script"; then
  echo "Script should not call remove-all-old-packages.sh" >&2
  exit 1
fi

echo "All tests passed."
