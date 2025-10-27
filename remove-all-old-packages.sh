#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin

apt-mark minimize-manual

if dpkg -s deborphan >/dev/null 2>&1; then
  apt-get purge -y deborphan
fi

for attempt in $(seq 1 10); do
  if apt-get autoremove --purge -y | grep -q '0 upgraded, 0 newly installed, 0 to remove'; then
    break
  fi
  echo "Running autoremove again to ensure all unnecessary packages are removed."
done
