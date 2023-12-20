#!/usr/bin/env bash
PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin
dpkg --configure -a && \
apt-get update && \
apt-get dist-upgrade -y && \
apt-get autoremove -y --purge && \
apt-get purge $(deborphan --guess-all)  -y
