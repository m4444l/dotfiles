---
name: figma
description: Export images and design assets from Figma designs using the Figma REST API. Use when implementing designs from Figma or extracting visual assets. Use when user shares a Figma URL, says "export from Figma", "get the design assets", or "implement this Figma design".
---

# Figma

Access Figma designs to inspect structure, extract design tokens, generate code, and export images.

## MCP Server First

Always try the Figma MCP server tool first. These provide direct access to design context, metadata, screenshots, variables, and code generation.

Only fall back to the REST API for use cases the MCP server cannot handle.

### Use cases requiring REST API fallback

- **Extracting embedded images** (background fills, image fills) — MCP has no equivalent to the `/files/:key/images` endpoint
- **Exporting nodes at specific scales/formats** — MCP screenshots are fixed; REST API supports `format` (png/jpg/svg/pdf) and `scale` (1x/2x/4x)
- **Batch exporting multiple nodes** in a single request

## REST API

For prerequisites (auth token, URL parsing), endpoints, common workflows, best practices, and troubleshooting, consult [references/rest-api.md](references/rest-api.md).
