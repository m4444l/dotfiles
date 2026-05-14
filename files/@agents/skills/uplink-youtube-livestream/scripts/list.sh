#!/usr/bin/env bash
# List YouTube livestream broadcasts
# Usage: list.sh <client_id> <client_secret> <refresh_token> [status]
# Status: upcoming (default), active, completed, all
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_token.sh"

CLIENT_ID="${1:-${YT_CLIENT_ID:-}}"
CLIENT_SECRET="${2:-${YT_CLIENT_SECRET:-}}"
REFRESH_TOKEN="${3:-${YT_REFRESH_TOKEN:-}}"
STATUS="${4:-upcoming}"

if [[ -z "$CLIENT_ID" || -z "$CLIENT_SECRET" || -z "$REFRESH_TOKEN" ]]; then
  echo "Usage: list.sh <client_id> <client_secret> <refresh_token> [status]" >&2
  exit 1
fi

_get_access_token "$CLIENT_ID" "$CLIENT_SECRET" "$REFRESH_TOKEN"

API="https://www.googleapis.com/youtube/v3"

if [[ "$STATUS" == "all" ]]; then
  FILTER="broadcastType=all"
else
  FILTER="broadcastStatus=${STATUS}"
fi

curl -sS -X GET "${API}/liveBroadcasts?part=snippet,status,contentDetails&${FILTER}&maxResults=50" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
