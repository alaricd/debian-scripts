#!/bin/bash
dpkg --configure -a
apt-get update
apt-get dist-upgrade -y
apt-get autoremove -y --purge
#apt-get autoclean 
#apt-get purge $(deborphan --guess-all | grep -v libaio1) -y
apt-get purge $(deborphan --guess-all)  -y
