#!/usr/bin/env bash

# List of packages to check and install if necessary
packages=("deborphan" "needrestart")

# Loop through the list of packages and install them if they are not already installed
for pkg in "${packages[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "$pkg is not installed. Installing..."
        sudo apt-get install -y "$pkg"
    else
        echo "$pkg is already installed."
    fi
done

echo "All packages checked and necessary ones installed."
