#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

if [[ "${DEBUG:-0}" == "1" ]]; then
  set -x
fi

PATH="${PATH:-/usr/bin:/bin:/usr/sbin:/sbin}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

running_release="$(uname -r)"
running_pkg=""
running_version=""

candidate_releases=("$running_release")
if [[ "$running_release" == *-amd64 ]]; then
  candidate_releases+=("${running_release/-amd64/-generic}")
fi

for release in "${candidate_releases[@]}"; do
  for prefix in linux-image linux-image-unsigned; do
    candidate="${prefix}-${release}"
    if dpkg-query -W -f='${Status}\n' "$candidate" 2>/dev/null | grep -q 'install ok installed'; then
      running_pkg="$candidate"
      running_version="$(dpkg-query -W -f='${Version}' "$candidate" 2>/dev/null || true)"
      break 2
    fi
  done
done

if [[ -z "$running_pkg" || -z "$running_version" ]]; then
  echo "Unable to determine running kernel package for ${running_release}" >&2
  exit 0
fi

mapfile -t installed_kernels < <(
  dpkg-query -W -f='${Package}\t${Version}\t${Status}\n' 'linux-image-*' 'linux-image-unsigned-*' 2>/dev/null || true
)

to_purge=()
for entry in "${installed_kernels[@]}"; do
  IFS=$'\t' read -r pkg_name pkg_version pkg_status <<< "$entry"

  if [[ "$pkg_status" != "install ok installed" ]]; then
    continue
  fi

  # Skip meta-packages that do not track a specific kernel ABI.
  if [[ ! "$pkg_name" =~ ^linux-image(-unsigned)?-[0-9] ]]; then
    continue
  fi

  if [[ "$pkg_name" == "$running_pkg" ]]; then
    continue
  fi

  if dpkg --compare-versions "$pkg_version" lt "$running_version"; then
    to_purge+=("$pkg_name")
  fi
done

if [[ "${#to_purge[@]}" -gt 0 ]]; then
  apt-get purge -y "${to_purge[@]}"
fi
