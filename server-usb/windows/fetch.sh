#!/bin/sh
# Download the Windows installers onto this folder.
# Run it on a computer with internet, then copy server-usb/windows to a USB stick.
#
#   sh server-usb/windows/fetch.sh arm64
#   sh server-usb/windows/fetch.sh amd64
#
# arm64 is Windows on ARM (an Apple Silicon UTM virtual machine).
# amd64 is a 64-bit Intel or AMD shop PC.
# With Docker on this computer, the shop program is packed onto the stick too.
set -eu

here=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
root=$(CDPATH= cd -- "$here/../.." && pwd)

print_urls=0
if [ "${1:-}" = "--print-urls" ]; then
  print_urls=1
  shift
fi

arch="${1:-}"
if [ -z "$arch" ]; then
  case "$(uname -m)" in
    arm64|aarch64) arch=arm64 ;;
    x86_64|amd64) arch=amd64 ;;
    *)
      echo "Name the Windows type: sh server-usb/windows/fetch.sh arm64"
      echo "                      sh server-usb/windows/fetch.sh amd64"
      exit 1
      ;;
  esac
fi

case "$arch" in
  arm64)
    docker_url="https://desktop.docker.com/win/main/arm64/Docker%20Desktop%20Installer.exe"
    wsl_suffix="arm64.msi"
    ;;
  amd64)
    docker_url="https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    wsl_suffix="x64.msi"
    ;;
  *)
    echo "Use arm64 or amd64."
    exit 1
    ;;
esac

if ! command -v curl >/dev/null 2>&1; then
  echo "This downloader needs curl."
  exit 1
fi

wsl_url=$(
  curl -fsSL -A "cooling-down-fetch" \
    "https://api.github.com/repos/microsoft/WSL/releases/latest" \
    | grep -o "https://github.com/microsoft/WSL/releases/download/[^\"]*${wsl_suffix}" \
    | head -n 1 || true
)
if [ -z "$wsl_url" ]; then
  echo "Could not find the WSL installer (${wsl_suffix})."
  exit 1
fi

if [ "$print_urls" -eq 1 ]; then
  printf '%s\n' "$docker_url"
  printf '%s\n' "$wsl_url"
  exit 0
fi

printf '%s\n' "$arch" > "$here/arch.txt"
echo "Downloading Docker Desktop for Windows ${arch}"
curl -fL --retry 3 --retry-delay 2 -o "$here/Docker Desktop Installer.exe" "$docker_url"
echo "Downloading WSL"
curl -fL --retry 3 --retry-delay 2 -o "$here/$(basename "$wsl_url")" "$wsl_url"

if command -v docker >/dev/null 2>&1; then
  bash "$root/server-ssh/pack-windows.sh"
  rm -rf "$here/cooling-down"
  cp -R "$root/server-ssh/dist/cooling-down" "$here/cooling-down"
else
  echo "Docker is not on this computer, so the shop program was not packed."
  echo "When Docker is available: bash server-ssh/pack-windows.sh"
  echo "Copy server-ssh/dist/cooling-down onto the stick, next to install.ps1."
fi

echo
echo "Copy this folder to the USB stick:"
echo "  $here"
echo "On Windows, in an Administrator PowerShell, from the folder on the stick:"
echo "  powershell -ExecutionPolicy Bypass -File .\\install.ps1"
echo "Restart, start Docker Desktop, and run that command again."
