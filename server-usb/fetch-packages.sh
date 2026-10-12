#!/bin/sh
# Download Docker and OpenSSH packages onto this folder.
# Run it on Ubuntu with internet, using the same Ubuntu version as the shop PC.
# Then copy the whole server-usb folder to a USB stick.
#   sudo sh fetch-packages.sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "Run: sudo sh fetch-packages.sh"
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This downloader needs apt-get. Use Ubuntu of the same version as the shop PC."
  exit 1
fi

here=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
packages="$here/packages"
mkdir -p "$packages/partial"

cache=$(mktemp -d)
trap 'rm -rf "$cache"' EXIT

apt-get update
apt-get install -y --download-only \
  -o "Dir::Cache=$cache" \
  -o "Dir::Cache::archives=$packages" \
  docker.io \
  openssh-server

if command -v lsb_release >/dev/null 2>&1; then
  lsb_release -ds > "$packages/os.txt"
else
  . /etc/os-release
  printf '%s\n' "$PRETTY_NAME" > "$packages/os.txt"
fi

echo "Saved packages for $(cat "$packages/os.txt") in $packages"
echo "Copy the server-usb folder to a USB stick. On the shop PC run: sudo sh install.sh"
