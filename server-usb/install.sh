#!/bin/sh
# Install Docker, Compose, and OpenSSH on a Linux shop computer when they are missing.
# Copy the server-usb folder onto a USB stick and run this there:
#   sudo sh install.sh
set -eu

here=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
packages="$here/packages"

has_docker=0
has_compose=0
has_ssh=0
if command -v docker >/dev/null 2>&1; then
  has_docker=1
fi
if docker compose version >/dev/null 2>&1; then
  has_compose=1
fi
if command -v sshd >/dev/null 2>&1; then
  has_ssh=1
fi

if [ "$has_docker" -eq 1 ] && [ "$has_compose" -eq 1 ] && [ "$has_ssh" -eq 1 ]; then
  echo "Docker, Compose, and SSH are already installed."
  exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this on the shop computer: sudo sh install.sh"
  exit 1
fi

deb_count=0
if [ -d "$packages" ]; then
  deb_count=$(find "$packages" -maxdepth 1 -name '*.deb' | wc -l | tr -d ' ')
fi

if [ "$deb_count" -gt 0 ]; then
  echo "Installing from the USB packages."
  apt-get install -y "$packages"/*.deb
else
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "This computer has no packages on the USB and no apt-get."
    echo "On an Ubuntu machine with internet, run server-usb/fetch-packages.sh and copy this folder again."
    echo "A Windows shop PC does not use this folder. Install Docker Desktop and see guide.txt."
    exit 1
  fi
  echo "No USB packages found. Installing Docker, Compose, and SSH from the internet."
  apt-get update
  apt-get install -y docker.io docker-compose-v2 openssh-server
fi

if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != root ]; then
  usermod -aG docker "$SUDO_USER"
  echo "Added $SUDO_USER to the docker group. Log out and back in before using docker."
fi

systemctl enable --now docker
if systemctl cat ssh.service >/dev/null 2>&1; then
  systemctl enable --now ssh
elif systemctl cat sshd.service >/dev/null 2>&1; then
  systemctl enable --now sshd
fi

echo "Docker, Compose, and SSH are installed."
echo "After the server is in place, close SSH at this computer with:"
echo "  sudo sh ~/cooling-down/ssh-window.sh 30"
