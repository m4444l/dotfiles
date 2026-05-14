---
name: browser-automation
description: Automate browser interactions for web testing, form filling, screenshots, and data extraction. Use when the user needs to navigate websites, interact with web pages, fill forms, take screenshots, test web applications, or extract information from web pages.
---

# Browser Automation

## Tools

Three tools are available for browser automation:

1. **agent-browser** — CLI tool for AI-driven browser automation.
2. **playwright-cli** — CLI tool for scripted browser automation. Preferred for most tasks.
3. **Chrome DevTools MCP** — MCP server for direct browser control via DevTools protocol.

**Default to agent-browser.** Fall back to playwright-cli if:
- agent-browser is not available
- The task requires precise, scripted automation without AI interaction

Only use Chrome DevTools MCP if:
- The task requires interacting with an already-open browser session
- The task specifically needs DevTools features (e.g. network inspection, performance tracing)

## agent-browser

For detailed instructions, read [references/agent-browser.md](references/agent-browser.md).

Run `agent-browser --help` to understand available commands, options, and usage.

## playwright-cli

For detailed instructions, read [references/playwright-cli.md](references/playwright-cli.md) and the reference documents in [references/playwright-cli/](references/playwright-cli/).

## Chrome DevTools MCP

For detailed instructions, read [references/chrome-devtools.md](references/chrome-devtools.md).

If the agent opens a new browser page via Chrome DevTools MCP, it must close that page when done (using `close_page`).
