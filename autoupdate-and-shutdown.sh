#!/usr/bin/env bash
PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin
/bin/remove-old-kernels.sh
/bin/remove-old-snaps.sh
/bin/autoupdate.sh
shutdown -h now
