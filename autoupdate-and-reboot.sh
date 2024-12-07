#!/usr/bin/env bash
PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin
if [ -n "$1" ]; then
  touch /var/run/reboot-required
fi
/bin/check-if-already-updating.sh && \
/bin/remove-old-kernels.sh && \
/bin/remove-all-old-packages.sh && \
/bin/remove-old-snaps.sh && \
/bin/autoupdate.sh
/bin/reboot-if-required.sh