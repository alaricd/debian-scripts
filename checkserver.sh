#!/usr/bin/env bash

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <host> <port>" >&2
    exit 1
fi

# Determine the directory of this script to call helpers reliably
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

nc -z "$1" "$2"
if [ $? -eq 1 ]; then
    "${SCRIPT_DIR}/autoupdate-and-reboot.sh"
fi


