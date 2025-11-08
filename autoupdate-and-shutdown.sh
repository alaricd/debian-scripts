#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

"${SCRIPT_DIR}/check-if-already-updating.sh"
"${SCRIPT_DIR}/remove-old-kernels.sh"
"${SCRIPT_DIR}/remove-old-snaps.sh"
"${SCRIPT_DIR}/remove-all-old-packages.sh"
"${SCRIPT_DIR}/autoupdate.sh"
shutdown -h now
