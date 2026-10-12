#!/usr/bin/env bash
# Build the shop-computer image and start it on a computer you can SSH into.
# The shop computer needs Docker. It does not need Dart.
#
#   tools/deploy.sh user@shop-pc
#   tools/deploy.sh --build-only
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
compose="$root/tools/docker-compose.yml"
image="$(awk '/^[[:space:]]*image:/ { print $2; exit }' "$compose")"
remote_dir="${DEPLOY_DIR:-cooling-down}"

usage() {
  echo "Usage: tools/deploy.sh user@host"
  echo "       tools/deploy.sh --build-only"
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
  docker build -t "$image" "$root/server"
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
docker build -t "$image" "$root/server"

echo "Sending $image to $target"
docker save "$image" | ssh "$target" docker load

ssh "$target" "mkdir -p ~/${remote_dir}/data"
scp "$compose" "${target}:${remote_dir}/docker-compose.yml"
scp "$root/tools/ssh-window.sh" "${target}:${remote_dir}/ssh-window.sh"
ssh "$target" "chmod 755 ~/${remote_dir}/ssh-window.sh"

if ssh "$target" "test -f ~/${remote_dir}/data/.env"; then
  echo "Keeping the .env already on the computer."
else
  scp "$root/server/.env.example" "${target}:${remote_dir}/data/.env"
  echo "Created data/.env from the example."
fi

ssh "$target" "cd ~/${remote_dir} && docker compose up -d"
echo
ssh "$target" "cd ~/${remote_dir} && docker compose logs --tail 40"

cat << EOF

The shop computer is listening on port 8080.
Tablets use http://<that-computer>:8080. They do not use SSH.

Still done on site, not by this script:
- Copy SYNC_TOKEN from the log above, or from ~/${remote_dir}/data/.env on the shop computer.
- Set ADMIN_USER, ADMIN_PASSWORD, and the mail fields in that file. Then run:
  ssh ${target} 'cd ~/${remote_dir} && docker compose up -d --force-recreate'
- Allow port 8080 from the shop Wi-Fi only.
- Install the tablet app from tablet/ on each device, and enter the address, the token, and the environment name.
- Install Docker and OpenSSH on the shop computer before the first run. Your user there must be allowed to run docker.
- Later visits: at the shop computer, run sudo sh ~/${remote_dir}/ssh-window.sh 30
  That opens SSH for 30 minutes and then closes it. Run it from the computer itself.
EOF
