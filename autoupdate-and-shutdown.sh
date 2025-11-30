#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PATH="${PATH:-/usr/bin:/bin:/usr/sbin:/sbin}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

"${SCRIPT_DIR}/check-if-already-updating.sh"
NO_REBOOT=1 "${SCRIPT_DIR}/autoupdate-and-reboot.sh"
shutdown -h now
