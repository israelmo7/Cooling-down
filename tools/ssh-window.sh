#!/bin/sh
# Open SSH for a short maintenance window, then close it.
# Run this at the shop computer, from its own keyboard:
#   sudo sh ssh-window.sh 30
# After the window, SSH stays off across a reboot until someone runs this there again.
set -eu

usage() {
  echo "Usage: sudo sh ssh-window.sh [minutes]"
  echo "Opens SSH for that many minutes. The default is 30. The maximum is 240."
  echo "Run it at the shop computer. When the window ends, new SSH logins stop."
  exit 1
}

minutes="${1:-30}"
case "$minutes" in
  ''|*[!0-9]*) usage ;;
esac
if [ "$minutes" -lt 1 ] || [ "$minutes" -gt 240 ]; then
  usage
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this at the shop computer with sudo."
  exit 1
fi

if ! command -v systemctl >/dev/null 2>&1 || ! command -v systemd-run >/dev/null 2>&1; then
  echo "This computer does not use systemd, so this script cannot open SSH."
  exit 1
fi

unit=""
if systemctl cat ssh.service >/dev/null 2>&1; then
  unit=ssh
elif systemctl cat sshd.service >/dev/null 2>&1; then
  unit=sshd
else
  echo "Install OpenSSH on this computer first."
  exit 1
fi

close_script=/usr/local/sbin/cooling-down-close-ssh
cat > "$close_script" << EOF
#!/bin/sh
systemctl stop ${unit}.service || true
systemctl disable ${unit}.service >/dev/null 2>&1 || true
if systemctl cat ${unit}.socket >/dev/null 2>&1; then
  systemctl stop ${unit}.socket || true
  systemctl disable ${unit}.socket >/dev/null 2>&1 || true
fi
EOF
chmod 755 "$close_script"

systemctl stop cooling-down-ssh-close.timer >/dev/null 2>&1 || true
systemctl reset-failed cooling-down-ssh-close.timer >/dev/null 2>&1 || true
systemctl reset-failed cooling-down-ssh-close.service >/dev/null 2>&1 || true

if ! systemd-run --unit=cooling-down-ssh-close --on-active="${minutes}min" "$close_script"; then
  echo "Could not schedule the close, so SSH was left as it was."
  exit 1
fi

if systemctl cat "${unit}.socket" >/dev/null 2>&1; then
  systemctl start "${unit}.socket"
fi
systemctl start "${unit}.service"
echo "SSH is open for ${minutes} minutes."
echo "A login that is already connected can finish after the window. New logins stop when it closes."
echo "SSH stays off after a reboot. Run this script at the computer when you need it again."
