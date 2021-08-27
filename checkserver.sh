#!/bin/bash
nc -z $1 $2
if [ $? -eq 1 ]; then
	/bin/autoupdate-and-reboot.sh
fi
