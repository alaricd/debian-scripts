#!/usr/bin/env bash
PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin
BASE=`apt-mark showinstall | grep ^linux-image | grep -v ^linux-image-[0-9]`
dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | grep -v `uname -r` | grep -v libc-dev | grep -v $BASE | xargs sudo apt-get -y purge
