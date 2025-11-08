#!/usr/bin/env bash
set -e

script="$(dirname "$0")/../check-requirements.sh"

# positive test: Kali packages exclude nc and include required tools
if ! grep -q 'packages=("sed" "needrestart" "fwupd")' "$script"; then
  echo "Expected Kali package list without nc" >&2
  exit 1
fi

# positive test: script checks for nc command before installing
if ! grep -q 'command -v nc >/dev/null 2>&1' "$script"; then
  echo "Expected check for nc command" >&2
  exit 1
fi

# positive test: script installs netcat-traditional when nc is absent
if ! grep -q 'apt-get install -y netcat-traditional' "$script"; then
  echo "Expected netcat-traditional installation command" >&2
  exit 1
fi

# positive test: script runs needrestart to restart services automatically
if ! grep -q 'needrestart -r a' "$script"; then
  echo "Expected needrestart automatic restart command" >&2
  exit 1
fi

# positive test: script includes fwupd in all package lists
if ! grep -q '"fwupd"' "$script"; then
  echo "Expected fwupd in package lists" >&2
  exit 1
fi

# negative test: script should not list nc as a package
if grep -q 'packages=("nc"' "$script"; then
  echo "Kali package list should not include nc" >&2
  exit 1
fi

# negative test: script should not attempt to install nc package
if grep -q 'apt-get install -y nc' "$script"; then
  echo "Script should not install nc package" >&2
  exit 1
fi

# negative test: script should not invoke needrestart interactively
if grep -q 'needrestart -r i' "$script"; then
  echo "Script should not run needrestart interactively" >&2
  exit 1
fi

echo "All tests passed."

