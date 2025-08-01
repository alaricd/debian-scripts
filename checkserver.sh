#!/usr/bin/env bash

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <host> <port>" >&2
    exit 1
fi

nc -z "$1" "$2"
if [ $? -eq 1 ]; then
    /bin/autoupdate-and-reboot.sh
fi


