---
name: ergo-portal
description: Download new PDF documents from the ERGO/DKV Kundenportal (meine.ergo.de). Use when checking for new ERGO/DKV documents, downloading Leistungsabrechnungen, or when an ERGO notification email arrives.
---

# ERGO Portal — PDF Download

Download new PDF documents from the ERGO/DKV Kundenportal for Karin Christa Meurer.

## Prerequisites

- **Browser**: Use the default Hermes browser profile/config for this installation (do not override profile/headless in the workflow). Chromium must be running with remote debugging (attachOnly setup; CDP endpoint is configured in Hermes).
- **1Password**: ERGO credentials in vault "Shared with Tom" (item "DKV / Ergo"). Load `OP_SERVICE_ACCOUNT_TOKEN` from the Hermes environment (`~/.hermes/.env`, mode `0600`; do not print secrets).
- **SMS Webhook**: OTP codes arrive in `/home/manuel/sms-memory/YYYY-MM.json` (JSON records; from/sender/text fields may vary).

## Workflow

### 1. Get credentials (1Password)

**Wichtig:** Credentials niemals in Chat/Logs ausgeben. Werte nur in Variablen halten und direkt zum Login verwenden.

```bash
# Load Hermes environment (no output)
set -euo pipefail
set -a
. ~/.hermes/.env
set +a

# Read fields into shell variables (do not echo)
# IMPORTANT: use --reveal for concealed fields. Without --reveal, `op --fields password`
# may return a long 1Password reference/placeholder instead of the actual password.
ERGO_USERNAME="$(op item get "DKV / Ergo" --vault "Shared with Tom" --fields username --reveal)"
ERGO_PASSWORD="$(op item get "DKV / Ergo" --vault "Shared with Tom" --fields password --reveal)"
```

Then use `ERGO_USERNAME` / `ERGO_PASSWORD` to fill the login form via the browser tool.

### 2. Open login page

- Navigate to `https://kunde-s.ergo.de/meineversicherungen/lz/start.aspx?vu=ergo`
- Wait for the login form (look for textbox "Benutzername" / "Passwort")

### 3. Log in

- Click username field, clear it, fill username
- Click password field, clear it, fill password
- **Before clicking "Anmelden", verify field lengths exactly match 1Password values**:
  - username field length must equal `ERGO_USERNAME.length`
  - password field length must equal `ERGO_PASSWORD.length`
  - password field type must still be `password` (not visible text)
- If any check fails, stop immediately; do **not** submit the form. Clear/refill once, then re-check.
- Click "Anmelden" only after the length/type check passes.
- Wait for dashboard ("Herzlich willkommen")

### 4. Navigate to Postfach

- Click "Postfach" link in the navigation
- Wait for message list to load

### 5. Identify new documents

**Only messages with a 📎 clip icon have PDF attachments.** In the accessibility tree, these show as `group "clip"` next to the message row.

Look for messages from the **last 2 days** that have a clip icon. These are the ones with downloadable PDFs.

**If multiple new documents exist**: Download only the most recent one. After sending it, inform the user that there are N more new documents with attachments from the last 2 days.

**If no new documents**: Inform the user that no new documents were found.

### 6. Open the message

- Click the message row (use `evaluate` with JS to click the table row matching the date and subject)
- Wait for message detail view (look for heading with the message subject)

### 7. Click the PDF link

- Find the link containing "(PDF)" in its text (e.g. "Leistungsabrechnung (PDF)")
- Click it
- This triggers the SMS-Kennwort flow

### 8. Request SMS-Kennwort

- On the OTP prompt page, click "SMS-Kennwort anfordern"
- Wait 5-10 seconds for the SMS to arrive

### 9. Read SMS code

Read the latest ERGO SMS from the Hermes SMS memory log:

```bash
jq -r '[.[] | select(((.from // .sender // .address // "") | ascii_upcase | contains("ERGO")) or ((.text // .body // .message // "") | ascii_upcase | contains("ERGO"))) ] | sort_by(.receivedAt // .timestamp // .date // "") | last | (.text // .body // .message)' /home/manuel/sms-memory/$(date +%Y-%m).json
```

Extract the 6-digit code from the SMS text. Do not print the code in chat/log output; keep it in a local variable and enter it directly.

### 10. Enter SMS code and unlock

- Type the code into the "SMS-Kennwort" textbox
- Click "Freischalten"
- The PDF downloads automatically to `~/Downloads/`

### 11. Send PDF via Telegram

Downloads in the Hermes Chromium profile typically land in `/home/manuel/Downloads/` (and may also use `/home/manuel/.hermes/browser/downloads/` depending on browser configuration). Check recent files and verify the MIME type before sending:

```bash
find /home/manuel/Downloads /home/manuel/.hermes/browser/downloads -maxdepth 1 -type f -mmin -10 2>/dev/null
file <path>
mkdir -p ~/.hermes/media/outbound
cp <path> ~/.hermes/media/outbound/<filename>.pdf
```

Then include `MEDIA:/home/manuel/.hermes/media/outbound/<filename>.pdf` in the final Telegram response.

### 12. Logout

- Click "Logout" link (top-right navigation)
- Confirm the page returns to the login screen

## Important Notes

- **Bot detection**: ERGO tends to block headless/automated traffic. Use the default Hermes GUI/non-headless browser setup configured for this install.
- **SMS timing**: After requesting the SMS-Kennwort, wait at least 5 seconds before checking the SMS log. If not found, retry after another 5 seconds (max 3 retries).
- **Session timeout**: ERGO sessions expire after ~15 minutes of inactivity. Complete the workflow promptly.
- **Message read state**: Both read and unread messages are relevant. Filter only by date and clip icon.
- **Driver quirks**: `slowly=true` may not be supported on this driver. Use regular `type` / `fill` / `press` for input.
