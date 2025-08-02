#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive
# List of packages to check and install if necessary

# Detect the distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
fi

# Define package lists specific to each distribution
if [ "$ID" == "kali" ]; then
    # Kali-specific package list (netcat is provided by default)
    packages=("sed" "deborphan" "needrestart")
    if ! command -v nc >/dev/null 2>&1; then
        echo "nc is not installed. Installing netcat-traditional..."
        apt-get install -y netcat-traditional
        if [ $? -ne 0 ]; then
            echo "Error installing netcat-traditional. Exiting."
            exit 1
        fi
    fi
elif [ "$ID" == "ubuntu" ]; then
    # Ubuntu-specific package list
    packages=("netcat-openbsd" "sed" "deborphan" "needrestart")
elif [ "$ID" == "debian" ]; then
    # Debian-specific package list
    packages=("netcat-openbsd" "sed" "deborphan" "needrestart")
else
    echo "Unsupported distribution: $ID"
    exit 1
fi

# Loop through the list of packages and install them if they are not already installed
for pkg in "${packages[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "$pkg is not installed. Installing..."
        apt-get install -y "$pkg"
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

if command -v needrestart >/dev/null 2>&1; then
    echo "Restarting services with stale binaries..."
    needrestart -r a
    if [ $? -ne 0 ]; then
        echo "needrestart failed. Exiting."
        exit 1
    fi
fi

echo "All packages checked and necessary ones installed."
