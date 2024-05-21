#!/usr/bin/env bash
PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin
/bin/check-if-already-updating.sh && \
/bin/remove-old-kernels.sh && \
/bin/remove-all-old-packages.sh && \
/bin/remove-old-snaps.sh && \
/bin/autoupdate.sh

if [ -f /var/run/reboot-required ] || [ -n "$1" ]; then
  echo 'reboot required'
  /sbin/reboot
fi
