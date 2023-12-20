#!/usr/bin/env bash
PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin
dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | grep -v `uname -r` | grep -v libc-dev | xargs sudo apt-get -y purge

