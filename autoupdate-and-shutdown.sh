#!/usr/bin/env bash
PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin

# Use SCRIPT_DIR for consistent invocation of companion scripts
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

"${SCRIPT_DIR}/remove-old-kernels.sh"
"${SCRIPT_DIR}/autoupdate.sh"
"${SCRIPT_DIR}/remove-old-snaps.sh"
shutdown -h now
