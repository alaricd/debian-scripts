#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PATH="${PATH:-/usr/bin:/bin:/usr/sbin:/sbin}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

yes | apt-mark minimize-manual || true

for attempt in $(seq 1 10); do
  if apt-get autoremove --purge -y | grep -q '0 upgraded, 0 newly installed, 0 to remove'; then
    break
  fi
  echo "Running autoremove again to ensure all unnecessary packages are removed."
done
