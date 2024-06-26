#!/usr/bin/env bash
# Check if apt-get or dpkg is running
if pidof apt-get > /dev/null || pidof dpkg > /dev/null; then
    echo "An update process is already running. Exiting..."
    exit 1
fi