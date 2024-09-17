#!/usr/bin/env bash
PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin
export DEBIAN_FRONTEND=noninteractive

dpkg --configure -a --force-confdef --force-confold && \
apt-get update && \
apt-get dist-upgrade -y && \
apt-get purge $(deborphan --guess-all | grep -v "$(apt-mark showmanual)" | tr '\n' ' ') -y && \
/bin/check-requirements.sh