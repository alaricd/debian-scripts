#!/usr/bin/env bash
PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin

# Determine the directory where this script lives so we can invoke
# companion scripts reliably when called from any location.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -n "$1" ]; then
    touch /var/run/reboot-required
fi

"${SCRIPT_DIR}/check-if-already-updating.sh" && \
"${SCRIPT_DIR}/remove-old-kernels.sh" && \
"${SCRIPT_DIR}/autoupdate.sh" && \
"${SCRIPT_DIR}/remove-old-snaps.sh" && \
"${SCRIPT_DIR}/reboot-if-required.sh"
