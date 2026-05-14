---
name: uplink-youtube-livestream
description: Schedule and manage YouTube livestreams for the Uplink channel via YouTube Data API v3. Supports creating, listing, updating, and deleting scheduled livestreams.
---

# Uplink YouTube Livestream

Manage YouTube livestreams for the Uplink channel (hello@uplink.tech) via the YouTube Data API v3.

## Credentials

Read from OpenClaw config (`~/.openclaw/openclaw.json`):

```bash
CLIENT_ID=$(jq -r '.skills.entries["uplink-youtube-livestream"].clientId' ~/.openclaw/openclaw.json)
CLIENT_SECRET=$(jq -r '.skills.entries["uplink-youtube-livestream"].clientSecret' ~/.openclaw/openclaw.json)
REFRESH_TOKEN=$(jq -r '.skills.entries["uplink-youtube-livestream"].refreshToken' ~/.openclaw/openclaw.json)
```

## Scripts

All scripts are in the `scripts/` directory relative to this SKILL.md. Pass credentials as the first three arguments.

### Schedule a livestream

```bash
./scripts/schedule.sh "$CLIENT_ID" "$CLIENT_SECRET" "$REFRESH_TOKEN" \
  "Title" "Description" "2026-02-15T19:00:00Z" "unlisted"
```

- Privacy: `public`, `unlisted` (default), or `private`
- Start time: ISO 8601 format (UTC recommended)
- Returns JSON with broadcast ID and stream details

### List livestreams

```bash
./scripts/list.sh "$CLIENT_ID" "$CLIENT_SECRET" "$REFRESH_TOKEN"
./scripts/list.sh "$CLIENT_ID" "$CLIENT_SECRET" "$REFRESH_TOKEN" "all"
```

- Status filter: `upcoming` (default), `active`, `completed`, `all`

### Update a livestream

```bash
./scripts/update.sh "$CLIENT_ID" "$CLIENT_SECRET" "$REFRESH_TOKEN" \
  "BROADCAST_ID" "New Title" "New description" "2026-02-16T20:00:00Z" "public"
```

- Pass empty string `""` for fields you don't want to change

### Delete a livestream

```bash
./scripts/delete.sh "$CLIENT_ID" "$CLIENT_SECRET" "$REFRESH_TOKEN" "BROADCAST_ID"
```

## Parsing output

All scripts return JSON. Use jq:

```bash
# Broadcast IDs and titles
... | jq -r '.items[] | "\(.id) - \(.snippet.title)"'

# Scheduled start times
... | jq -r '.items[] | "\(.snippet.title): \(.snippet.scheduledStartTime)"'
```

## Notes

- Token refresh is handled automatically by each script
- Livestreams are created as broadcasts with a bound stream (auto-start/stop enabled)
- Requires `curl` and `jq`
