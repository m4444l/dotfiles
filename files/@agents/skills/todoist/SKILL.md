---
name: todoist
description: Manage Todoist tasks and projects via REST API. Use for listing, creating, updating, completing, and deleting tasks. Also supports projects, labels, and due dates.
---

# Todoist

Manage tasks and projects via Todoist REST API v1.

## Credentials

Use `TODOIST_API_TOKEN` from the Hermes environment (`~/.hermes/.env`, mode `0600`).

Get the token from: https://app.todoist.com/prefs/integrations (scroll to "API token")

## Scripts

All scripts are in the `scripts/` directory relative to this SKILL.md.

### Tasks

```bash
./scripts/todoist.sh tasks                    # All active tasks
./scripts/todoist.sh tasks "today"            # Filter: due today
./scripts/todoist.sh tasks "overdue"          # Filter: past due
./scripts/todoist.sh tasks "#Work"            # Filter: by project
./scripts/todoist.sh tasks "p1"              # Filter: by priority
./scripts/todoist.sh task TASK_ID             # Single task
```

### Create / Update / Complete

```bash
./scripts/todoist.sh add "Buy milk"
./scripts/todoist.sh add "Call dentist" "tomorrow"
./scripts/todoist.sh add "Meeting prep" "today 2pm" "PROJECT_ID"
./scripts/todoist.sh update TASK_ID "content=New title"
./scripts/todoist.sh update TASK_ID "due_string=next week" "priority=4"
./scripts/todoist.sh complete TASK_ID
./scripts/todoist.sh reopen TASK_ID
./scripts/todoist.sh delete TASK_ID
```

### Projects & Labels

```bash
./scripts/todoist.sh projects
./scripts/todoist.sh add-project "Project Name"
./scripts/todoist.sh labels
```

## Notes

- Priority: 4=urgent (p1), 3=high (p2), 2=medium (p3), 1=normal (p4)
- All output is JSON — parse with jq
- Requires `curl` and `jq`
