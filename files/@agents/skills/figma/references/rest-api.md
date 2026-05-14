# Figma REST API Reference

## Prerequisites

**Personal Access Token:**

Retrieve the token from 1Password once at the start and cache it in a temp file. This avoids repeated `op` confirmation prompts:

```bash
op item get jyitxg337vc2paqcunx3xthq4m --fields "label=Personal Access Token" --reveal > /tmp/.figma_token
```

Then read from the temp file in all subsequent curl commands:

```bash
curl -s -H "X-FIGMA-TOKEN: $(cat /tmp/.figma_token)" "https://api.figma.com/v1/..."
```

**Important:** Only call `op item get` once per session. All subsequent API calls should read from `/tmp/.figma_token`. Clean up when done: `rm /tmp/.figma_token`.

**Extract File Key and Node ID from URL:**

Given a Figma URL like:
```
https://www.figma.com/design/FCMSR0Qsq2jJo2Qfs0yr1s/ProjectName?node-id=3477-44&t=...
```

Extract:
- **File Key:** `FCMSR0Qsq2jJo2Qfs0yr1s`
- **Node ID:** `3477-44` (convert to `3477:44` for API — replace `-` with `:`)

## Endpoints

### Get Node Structure

```bash
curl -s -H "X-FIGMA-TOKEN: $(cat /tmp/.figma_token)" \
  "https://api.figma.com/v1/files/$FILE_KEY/nodes?ids=$NODE_ID"
```

Response includes: node hierarchy, fills (colors, images), imageRef references, dimensions, typography.

### Get Embedded Image URLs

```bash
curl -s -H "X-FIGMA-TOKEN: $(cat /tmp/.figma_token)" \
  "https://api.figma.com/v1/files/$FILE_KEY/images"
```

Returns map of `imageRef` to signed S3 URL (expire after ~7 days).

### Export Node as Image

```bash
curl -s -H "X-FIGMA-TOKEN: $(cat /tmp/.figma_token)" \
  "https://api.figma.com/v1/images/$FILE_KEY?ids=$NODE_ID&format=png&scale=2"
```

Options: `format` (png/jpg/svg/pdf), `scale` (1/2/4), multiple IDs comma-separated.

Returns JSON with `images` object mapping node IDs to temporary S3 URLs.

## Common Workflows

### Extract Background Image from Frame

```bash
# 1. Get node structure to find imageRef
curl -s -H "X-FIGMA-TOKEN: $(cat /tmp/.figma_token)" \
  "https://api.figma.com/v1/files/$FILE_KEY/nodes?ids=$NODE_ID" | \
  jq '.nodes | .. | .imageRef? | select(. != null)'

# 2. Get image URLs
curl -s -H "X-FIGMA-TOKEN: $(cat /tmp/.figma_token)" \
  "https://api.figma.com/v1/files/$FILE_KEY/images" | \
  jq '.meta.images["IMAGE_REF"]'

# 3. Download the image
curl -s -o background.jpg "IMAGE_URL"
```

### Export Node as Image

```bash
# 1. Export node as PNG at 2x
curl -s -H "X-FIGMA-TOKEN: $(cat /tmp/.figma_token)" \
  "https://api.figma.com/v1/images/$FILE_KEY?ids=$NODE_ID&format=png&scale=2" | \
  jq -r '.images["'"$NODE_ID"'"]'

# 2. Download using the returned URL
curl -s -o export.png "RETURNED_URL"
```

### Export Multiple Frames

```bash
curl -s -H "X-FIGMA-TOKEN: $(cat /tmp/.figma_token)" \
  "https://api.figma.com/v1/images/$FILE_KEY?ids=1:2,3:4,5:6&format=png&scale=2"
```

### Compare Design vs Implementation

```bash
# 1. Export Figma design
curl -s -H "X-FIGMA-TOKEN: $(cat /tmp/.figma_token)" \
  "https://api.figma.com/v1/images/$FILE_KEY?ids=$NODE_ID&format=png&scale=2"

# 2. Screenshot implementation (use browser MCP)

# 3. Compare visually
```

## Image Types

**Embedded Images (imageRef):** background fills, image fills, component assets. Full resolution, permanent references (until design changes).

**Exported Images:** rendered output of any node, flattened with effects. Temporary URLs, configurable resolution/format.

## Best Practices

1. **Cache image URLs** — S3 URLs expire, download immediately
2. **Use 2x scale** for high-DPI displays (Retina)
3. **Prefer PNG** for UI elements (transparency support)
4. **Use JPG** for photos/backgrounds (smaller file size)
5. **Store imageRef** not URLs (URLs are temporary)
6. **Batch exports** — extract multiple images in single API call
7. **Never commit tokens** to git

## Troubleshooting

- **401 Unauthorized** — check token validity and file access
- **404 Not Found** — verify file key and node ID; use `:` not `-` for API calls
- **Empty images object** — node has no embedded images; try exporting instead
- **Rate Limits** — 100 req/min per token; use batch exports

## API Reference

Full docs: https://www.figma.com/developers/api

Key endpoints:
- `GET /v1/files/:file_key/nodes` — Node details
- `GET /v1/files/:file_key/images` — Embedded images
- `GET /v1/images/:file_key` — Export nodes
- `GET /v1/files/:file_key` — Full file structure
