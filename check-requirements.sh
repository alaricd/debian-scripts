#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

export DEBIAN_FRONTEND=noninteractive

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
fi

declare -a packages
x_installed=0

case "${ID:-}" in
  kali)
    packages=("sed" "needrestart" "fwupd")
    if ! command -v nc >/dev/null 2>&1; then
      echo "nc is not installed. Installing netcat-traditional..."
      if ! apt-get install -y netcat-traditional; then
        echo "Error installing netcat-traditional. Exiting."
        exit 1
      fi
    fi
    ;;
  ubuntu|debian)
    packages=("netcat-openbsd" "sed" "needrestart" "fwupd")
    ;;
  "")
    echo "Warning: could not detect distribution; defaulting to Debian package set."
    packages=("netcat-openbsd" "sed" "needrestart" "fwupd")
    ;;
  *)
    echo "Unsupported distribution: ${ID}" >&2
    exit 1
    ;;
esac

if command -v Xorg >/dev/null 2>&1 || dpkg -s xorg >/dev/null 2>&1 || dpkg -s xserver-xorg-core >/dev/null 2>&1; then
  x_installed=1
fi

if [[ "$x_installed" == "1" ]]; then
  # Only install bleachbit when an X install is already present.
  packages+=("bleachbit")
fi

for pkg in "${packages[@]}"; do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    echo "$pkg is not installed. Installing..."
    if ! apt-get install -y "$pkg"; then
      echo "Error installing $pkg. Exiting."
      exit 1
    fi
    if [[ "$pkg" == "needrestart" ]]; then
      echo "configuring needrestart..."
      sed -i 's/#\$nrconf{restart} = .*/\$nrconf{restart} = "a";/' /etc/needrestart/needrestart.conf
    fi
  else
    echo "$pkg is already installed."
  fi
done

if command -v needrestart >/dev/null 2>&1; then
  echo "Restarting services with stale binaries..."
  if ! needrestart -r a; then
    echo "needrestart failed. Exiting."
    exit 1
  fi
fi

echo "All packages checked and necessary ones installed."
