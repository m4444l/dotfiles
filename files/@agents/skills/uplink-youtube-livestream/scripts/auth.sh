#!/usr/bin/env bash
# YouTube OAuth 2.0 authorization flow
# Usage: auth.sh <client_id> <client_secret>
set -eo pipefail

CLIENT_ID="${1:-${YT_CLIENT_ID:-}}"
CLIENT_SECRET="${2:-${YT_CLIENT_SECRET:-}}"

if [[ -z "$CLIENT_ID" || -z "$CLIENT_SECRET" ]]; then
  echo "Usage: auth.sh <client_id> <client_secret>" >&2
  exit 1
fi

SCOPE="https://www.googleapis.com/auth/youtube"
REDIRECT_URI="urn:ietf:wg:oauth:2.0:oob"

echo ""
echo "Open this URL in your browser and sign in with hello@uplink.tech:"
echo ""
echo "https://accounts.google.com/o/oauth2/v2/auth?client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&response_type=code&scope=${SCOPE}&access_type=offline&prompt=consent"
echo ""
read -rp "Paste the authorization code here: " AUTH_CODE

RESPONSE=$(curl -sS -X POST "https://oauth2.googleapis.com/token" \
  -d "code=${AUTH_CODE}" \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  -d "redirect_uri=${REDIRECT_URI}" \
  -d "grant_type=authorization_code")

REFRESH_TOKEN=$(echo "$RESPONSE" | jq -r '.refresh_token // empty')

if [[ -z "$REFRESH_TOKEN" ]]; then
  echo "Error: Failed to get refresh token" >&2
  echo "$RESPONSE" >&2
  exit 1
fi

echo ""
echo "Success! Store this refresh token in your OpenClaw config:"
echo ""
echo "  skills.entries.uplink-youtube-livestream.refreshToken = ${REFRESH_TOKEN}"
echo ""
