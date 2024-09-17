#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive
# List of packages to check and install if necessary
packages=("nc", "sed", "deborphan" "needrestart")

# Loop through the list of packages and install them if they are not already installed
for pkg in "${packages[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "$pkg is not installed. Installing..."
        sudo apt-get install -y "$pkg"
        if [ $? -ne 0 ]; then
            echo "Error installing $pkg. Exiting."
            exit 1
        fi
        if [ "$pkg" == "needrestart" ]; then
            echo "configuring needrestart..."
            sed -i 's/#\$nrconf{restart} = .*/\$nrconf{restart} = "a";/' /etc/needrestart/needrestart.conf

        fi
    else
        echo "$pkg is already installed."
    fi
done

echo "All packages checked and necessary ones installed."
