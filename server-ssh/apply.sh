#!/bin/sh
# Read shop.json in this folder and restart the shop program.
#   sh apply.sh
set -eu
cd "$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
mkdir -p data
# data/shop.json is newer after /admin saves. An edited shop.json here replaces it.
if [ -f data/shop.json ] && [ data/shop.json -nt shop.json ]; then
  cp data/shop.json shop.json
fi
cp shop.json data/shop.json
docker compose run -T --rm --no-deps server --apply-shop
cp data/shop.json shop.json
docker compose up -d --force-recreate
docker compose logs --tail 40
token=$(sed -n 's/^SYNC_TOKEN=//p' data/.env | tail -n 1)
token=${token#\"}
token=${token%\"}
printf '\nToken: %s\n' "$token"
printf 'Tablets: http://<this-computer>:8080\n'
printf 'Admin:   http://<this-computer>:8080/admin\n'
