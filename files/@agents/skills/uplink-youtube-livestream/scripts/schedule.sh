#!/usr/bin/env bash
# Schedule a new YouTube livestream
# Usage: schedule.sh <client_id> <client_secret> <refresh_token> <title> <description> <scheduled_start_time> [privacy]
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_token.sh"

CLIENT_ID="${1:-${YT_CLIENT_ID:-}}"
CLIENT_SECRET="${2:-${YT_CLIENT_SECRET:-}}"
REFRESH_TOKEN="${3:-${YT_REFRESH_TOKEN:-}}"
TITLE="${4:?title required}"
DESCRIPTION="${5:-}"
SCHEDULED_START="${6:?scheduled_start_time required (ISO 8601)}"
PRIVACY="${7:-unlisted}"

if [[ -z "$CLIENT_ID" || -z "$CLIENT_SECRET" || -z "$REFRESH_TOKEN" ]]; then
  echo "Usage: schedule.sh <client_id> <client_secret> <refresh_token> <title> <description> <start_time> [privacy]" >&2
  exit 1
fi

_get_access_token "$CLIENT_ID" "$CLIENT_SECRET" "$REFRESH_TOKEN"

API="https://www.googleapis.com/youtube/v3"

# Create the broadcast
BROADCAST=$(curl -sS -X POST "${API}/liveBroadcasts?part=snippet,status,contentDetails" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg title "$TITLE" \
    --arg desc "$DESCRIPTION" \
    --arg start "$SCHEDULED_START" \
    --arg privacy "$PRIVACY" \
    '{
      snippet: {
        title: $title,
        description: $desc,
        scheduledStartTime: $start
      },
      status: {
        privacyStatus: $privacy,
        selfDeclaredMadeForKids: false
      },
      contentDetails: {
        enableAutoStart: true,
        enableAutoStop: true,
        enableDvr: true,
        latencyPreference: "normal"
      }
    }')")

BROADCAST_ID=$(echo "$BROADCAST" | jq -r '.id // empty')

if [[ -z "$BROADCAST_ID" ]]; then
  echo "Error: Failed to create broadcast" >&2
  echo "$BROADCAST" >&2
  exit 1
fi

# Create a default stream
STREAM=$(curl -sS -X POST "${API}/liveStreams?part=snippet,cdn" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg title "${TITLE} - Stream" \
    '{
      snippet: { title: $title },
      cdn: {
        frameRate: "variable",
        ingestionType: "rtmp",
        resolution: "variable"
      }
    }')")

STREAM_ID=$(echo "$STREAM" | jq -r '.id // empty')

if [[ -n "$STREAM_ID" ]]; then
  # Bind stream to broadcast
  curl -sS -X POST "${API}/liveBroadcasts/bind?id=${BROADCAST_ID}&part=id,contentDetails&streamId=${STREAM_ID}" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" > /dev/null
fi

# Return the broadcast details
echo "$BROADCAST"
