#!/usr/bin/env bash
# Internal: get a fresh access token from refresh token
# Sources by other scripts, not called directly
# Sets ACCESS_TOKEN variable

_get_access_token() {
  local client_id="$1" client_secret="$2" refresh_token="$3"
  
  local response
  response=$(curl -sS -X POST "https://oauth2.googleapis.com/token" \
    -d "client_id=${client_id}" \
    -d "client_secret=${client_secret}" \
    -d "refresh_token=${refresh_token}" \
    -d "grant_type=refresh_token")
  
  ACCESS_TOKEN=$(echo "$response" | jq -r '.access_token // empty')
  
  if [[ -z "$ACCESS_TOKEN" ]]; then
    echo "Error: Failed to refresh access token" >&2
    echo "$response" >&2
    exit 1
  fi
}
