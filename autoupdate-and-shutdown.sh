#!/bin/bash
/bin/remove-old-kernels.sh
/bin/remove-old-snaps.sh
/bin/autoupdate.sh
shutdown -h now
