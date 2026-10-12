#!/usr/bin/env bash
# Build a folder you can copy onto a Windows shop PC.
# Run this on a computer that already has Docker. The shop PC does not build it.
#
#   sh server-ssh/pack-windows.sh
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
compose="$root/server-ssh/docker-compose.yml"
image="$(awk '/^[[:space:]]*image:/ { print $2; exit }' "$compose")"
out="$root/server-ssh/dist/cooling-down"

if ! command -v docker >/dev/null 2>&1; then
  echo "Install Docker on this machine. It builds the image."
  exit 1
fi

rm -rf "$out"
mkdir -p "$out"
echo "Building $image for Windows Docker Desktop (linux/amd64)"
docker build --platform linux/amd64 -t "$image" "$root/server-ssh"
docker save "$image" -o "$out/cooling-down-server.tar"
cp "$compose" "$out/docker-compose.yml"
cp "$root/server-ssh/shop.json" "$out/shop.json"
cp "$root/server-ssh/start.ps1" "$out/start.ps1"

echo
echo "Copy this folder to the Windows PC:"
echo "  $out"
echo "Install Docker Desktop there, edit shop.json, then in PowerShell:"
echo "  powershell -ExecutionPolicy Bypass -File .\\start.ps1"
