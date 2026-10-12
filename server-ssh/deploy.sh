#!/usr/bin/env bash
# Build the shop-computer image and start it on a computer you can SSH into.
# The shop computer needs Docker. It does not need Dart.
#
#   server-ssh/deploy.sh user@shop-pc
#   server-ssh/deploy.sh --build-only
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
compose="$root/server-ssh/docker-compose.yml"
image="$(awk '/^[[:space:]]*image:/ { print $2; exit }' "$compose")"
remote_dir="${DEPLOY_DIR:-cooling-down}"

usage() {
  echo "Usage: server-ssh/deploy.sh user@host"
  echo "       server-ssh/deploy.sh --build-only"
  echo "Builds the shop-computer image and starts it on that host."
  exit 1
}

case "$remote_dir" in
  ''|/*|*..*|*[!A-Za-z0-9._-]*)
    echo "DEPLOY_DIR must be a single folder name under the home directory."
    exit 1
    ;;
esac

if ! command -v docker >/dev/null 2>&1; then
  echo "Install Docker on this machine. It builds the image. The shop computer needs Docker too."
  exit 1
fi

if [[ "${1:-}" == "--build-only" ]]; then
  docker build -t "$image" "$root/server-ssh"
  echo "Built $image"
  exit 0
fi

if [[ $# -ne 1 || "$1" == "-h" || "$1" == "--help" ]]; then
  usage
fi

target="$1"
if [[ "$target" != *@* || "$target" == *@ || "$target" == @* ]]; then
  echo "The host must look like user@computer."
  exit 1
fi

echo "Checking Docker on $target"
ssh "$target" "docker compose version"

echo "Building $image"
docker build -t "$image" "$root/server-ssh"

echo "Sending $image to $target"
docker save "$image" | ssh "$target" docker load

ssh "$target" "mkdir -p ~/${remote_dir}/data"
scp "$compose" "${target}:${remote_dir}/docker-compose.yml"
scp "$root/server-ssh/ssh-window.sh" "${target}:${remote_dir}/ssh-window.sh"
scp "$root/server-ssh/apply.sh" "${target}:${remote_dir}/apply.sh"
ssh "$target" "chmod 755 ~/${remote_dir}/ssh-window.sh ~/${remote_dir}/apply.sh"

if ssh "$target" "test -f ~/${remote_dir}/shop.json"; then
  echo "Keeping the shop.json already on the computer."
else
  scp "$root/server-ssh/shop.json" "${target}:${remote_dir}/shop.json"
  echo "Created shop.json on the computer."
fi

ssh "$target" "sh ~/${remote_dir}/apply.sh"

cat << EOF

Listening on port 8080. The token is printed above.
Tablets use http://<that-computer>:8080. They do not use SSH.
Edit ~/${remote_dir}/shop.json on the shop computer, then run: sh ~/${remote_dir}/apply.sh
A later deploy keeps that shop.json.
Linux only: sudo sh ~/${remote_dir}/ssh-window.sh 30 opens SSH for 30 minutes.
A Windows shop PC does not use this script. See guide.txt.
EOF
