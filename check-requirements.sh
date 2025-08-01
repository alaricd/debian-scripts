#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive
# List of packages to check and install if necessary. `deborphan` has been
# removed from modern Debian-based systems and will be purged if present.

# Detect the distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
fi

# Define package lists specific to each distribution using a case statement
case "$ID" in
    kali)
        # Kali-specific package list (netcat is already included by default)
        packages=("nc" "sed" "needrestart")
        ;;
    ubuntu|debian)
        # Ubuntu and Debian package list
        packages=("netcat-openbsd" "sed" "needrestart")
        ;;
    *)
        echo "Unsupported distribution: $ID"
        exit 1
        ;;
esac

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

echo "All packages checked and necessary ones installed."

# Purge deborphan if it still exists
if dpkg -s deborphan >/dev/null 2>&1; then
    apt-get purge -y deborphan
fi

