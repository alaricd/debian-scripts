#!/usr/bin/env bash
PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin
export DEBIAN_FRONTEND=noninteractive

dpkg --configure -a --force-confdef --force-confold && \
apt-get update && \
apt-get dist-upgrade -y && \
"$(dirname "$0")/remove-all-old-packages.sh" && \
"/bin/check-requirements.sh"

