#!/bin/bash
#/var/lib/dpkg/lock
/bin/remove-old-kernels.sh && \
/bin/remove-old-snaps.sh && \
/bin/autoupdate.sh
if [ -f /var/run/reboot-required ] || [ -n "$1" ]; then
  echo 'reboot required'
  /sbin/reboot
fi
