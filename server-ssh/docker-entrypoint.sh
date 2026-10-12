#!/bin/sh
# Midnight follows TZ in /data/.env, which shop.json writes. Default: Asia/Jerusalem.
set -eu
tz=Asia/Jerusalem
if [ -f /data/.env ]; then
  line=$(grep -E '^TZ=' /data/.env | tail -n 1 || true)
  value=${line#TZ=}
  value=$(printf '%s' "$value" | tr -d '\r')
  case "$value" in
    \"*\") value=${value#\"}; value=${value%\"} ;;
    \'*\') value=${value#\'}; value=${value%\'} ;;
  esac
  if [ -n "$value" ]; then
    tz=$value
  fi
fi
export TZ="$tz"
exec /opt/cooling-down/bin/server "$@"
