#!/usr/bin/env bash
# Update a YouTube livestream broadcast
# Usage: update.sh <client_id> <client_secret> <refresh_token> <broadcast_id> [title] [description] [start_time] [privacy]
# Pass empty string "" for fields you don't want to change
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_token.sh"

CLIENT_ID="${1:-${YT_CLIENT_ID:-}}"
CLIENT_SECRET="${2:-${YT_CLIENT_SECRET:-}}"
REFRESH_TOKEN="${3:-${YT_REFRESH_TOKEN:-}}"
BROADCAST_ID="${4:?broadcast_id required}"
NEW_TITLE="${5:-}"
NEW_DESC="${6:-}"
NEW_START="${7:-}"
NEW_PRIVACY="${8:-}"

if [[ -z "$CLIENT_ID" || -z "$CLIENT_SECRET" || -z "$REFRESH_TOKEN" ]]; then
  echo "Usage: update.sh <client_id> <client_secret> <refresh_token> <broadcast_id> [title] [desc] [start] [privacy]" >&2
  exit 1
fi

_get_access_token "$CLIENT_ID" "$CLIENT_SECRET" "$REFRESH_TOKEN"

API="https://www.googleapis.com/youtube/v3"

# Fetch current broadcast to preserve unchanged fields
CURRENT=$(curl -sS -X GET "${API}/liveBroadcasts?part=snippet,status&id=${BROADCAST_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

ITEM=$(echo "$CURRENT" | jq '.items[0]')

if [[ "$ITEM" == "null" || -z "$ITEM" ]]; then
  echo "Error: Broadcast ${BROADCAST_ID} not found" >&2
  exit 1
fi

# Build update payload, merging current values with new ones
PAYLOAD=$(echo "$ITEM" | jq \
  --arg id "$BROADCAST_ID" \
  --arg title "$NEW_TITLE" \
  --arg desc "$NEW_DESC" \
  --arg start "$NEW_START" \
  --arg privacy "$NEW_PRIVACY" \
  '{
    id: $id,
    snippet: {
      title: (if $title != "" then $title else .snippet.title end),
      description: (if $desc != "" then $desc else .snippet.description end),
      scheduledStartTime: (if $start != "" then $start else .snippet.scheduledStartTime end)
    },
    status: {
      privacyStatus: (if $privacy != "" then $privacy else .status.privacyStatus end),
      selfDeclaredMadeForKids: false
    }
  }')

curl -sS -X PUT "${API}/liveBroadcasts?part=snippet,status" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"
