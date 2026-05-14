#!/usr/bin/env bash
# Delete/cancel a YouTube livestream broadcast
# Usage: delete.sh <client_id> <client_secret> <refresh_token> <broadcast_id>
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_token.sh"

CLIENT_ID="${1:-${YT_CLIENT_ID:-}}"
CLIENT_SECRET="${2:-${YT_CLIENT_SECRET:-}}"
REFRESH_TOKEN="${3:-${YT_REFRESH_TOKEN:-}}"
BROADCAST_ID="${4:?broadcast_id required}"

if [[ -z "$CLIENT_ID" || -z "$CLIENT_SECRET" || -z "$REFRESH_TOKEN" ]]; then
  echo "Usage: delete.sh <client_id> <client_secret> <refresh_token> <broadcast_id>" >&2
  exit 1
fi

_get_access_token "$CLIENT_ID" "$CLIENT_SECRET" "$REFRESH_TOKEN"

API="https://www.googleapis.com/youtube/v3"

HTTP_CODE=$(curl -sS -o /dev/null -w "%{http_code}" -X DELETE \
  "${API}/liveBroadcasts?id=${BROADCAST_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

if [[ "$HTTP_CODE" == "204" ]]; then
  echo '{"status":"deleted","broadcastId":"'"${BROADCAST_ID}"'"}'
else
  echo "Error: Delete returned HTTP ${HTTP_CODE}" >&2
  exit 1
fi
