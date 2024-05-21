#!/usr/bin/env bash
PATH=/bin:/usr/sbin:/sbin:/usr/local/sbin
# Removes old revisions of snaps
# CLOSE ALL SNAPS BEFORE RUNNING THIS
set -eu

# Check if snap is installed
if ! command -v snap &> /dev/null; then
    echo "Snap is not installed. Skipping snap cleanup."
    exit 0
fi

echo "Refreshing snaps"
snap refresh

# Check if there are any snaps installed
if snap list --all | grep -q disabled; then
    echo "Removing old snaps"
    LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}' |
        while read snapname revision; do
            snap remove "$snapname" --revision="$revision"
        done
    echo "Done with snap cleanup"
else
    echo "No old snaps to remove."
fi
