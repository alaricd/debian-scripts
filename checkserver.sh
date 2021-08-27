#!/bin/bash
nc -z mx.pengdows.com 25
if [ $? -eq 1 ]; then
	/bin/autoupdate-and-reboot.sh
fi
