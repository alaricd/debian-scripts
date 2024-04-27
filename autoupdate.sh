#!/usr/bin/env bash
PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin
SAVED_PACKAGES=$(apt-mark showmanual)
dpkg --configure -a && \
apt-get update && \
apt-get dist-upgrade -y && \
sudo apt-get purge $(deborphan --guess-all | grep -v "$(apt-mark showmanual)" | tr '\n' ' ') -y

