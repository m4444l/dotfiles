#!/usr/bin/env bash
# Todoist CLI via REST API v1
# Usage: todoist.sh <command> [args...]
# Token read from TODOIST_API_TOKEN env var (Hermes loads ~/.hermes/.env).

set -eo pipefail

API="https://api.todoist.com/api/v1"
cmd="${1:-help}"

# Resolve token from environment
get_token() {
  if [[ -n "${TODOIST_API_TOKEN:-}" ]]; then
    echo "$TODOIST_API_TOKEN"
    return
  fi
  echo "Error: No token found. Set TODOIST_API_TOKEN." >&2
  exit 1
}

if [[ "$cmd" != "help" ]]; then
  token=$(get_token)
fi

auth() { echo "Authorization: Bearer $token"; }
reqid() { uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid; }

case "$cmd" in
  tasks|filter)
    filter="${2:-}"
    if [[ -n "$filter" ]]; then
      # Todoist API v1 filter endpoint uses /tasks/filter?query=... .
      # /tasks?filter=... is ignored and returns unfiltered active tasks.
      curl -sS -X GET "$API/tasks/filter?query=$(printf '%s' "$filter" | jq -sRr @uri)" -H "$(auth)" | jq '.results // .'
    else
      curl -sS -X GET "$API/tasks" -H "$(auth)" | jq '.results // .'
    fi
    ;;

  task)
    task_id="${2:?task_id required}"
    curl -sS -X GET "$API/tasks/$task_id" -H "$(auth)"
    ;;

  add)
    content="${2:?content required}"
    due_string="${3:-}"
    project_id="${4:-}"

    json="{\"content\":$(echo "$content" | jq -R .)}"
    [[ -n "$due_string" ]] && json=$(echo "$json" | jq --arg d "$due_string" '. + {due_string: $d}')
    [[ -n "$project_id" ]] && json=$(echo "$json" | jq --arg p "$project_id" '. + {project_id: $p}')

    curl -sS -X POST "$API/tasks" \
      -H "$(auth)" \
      -H "Content-Type: application/json" \
      -H "X-Request-Id: $(reqid)" \
      -d "$json"
    ;;

  complete)
    task_id="${2:?task_id required}"
    curl -sS -X POST "$API/tasks/$task_id/close" -H "$(auth)"
    echo '{"ok":true}'
    ;;

  reopen)
    task_id="${2:?task_id required}"
    curl -sS -X POST "$API/tasks/$task_id/reopen" -H "$(auth)"
    echo '{"ok":true}'
    ;;

  update)
    task_id="${2:?task_id required}"
    shift 2
    json="{}"
    for pair in "$@"; do
      key="${pair%%=*}"
      val="${pair#*=}"
      json=$(echo "$json" | jq --arg k "$key" --arg v "$val" '. + {($k): $v}')
    done
    curl -sS -X POST "$API/tasks/$task_id" \
      -H "$(auth)" \
      -H "Content-Type: application/json" \
      -H "X-Request-Id: $(reqid)" \
      -d "$json"
    ;;

  delete)
    task_id="${2:?task_id required}"
    curl -sS -X DELETE "$API/tasks/$task_id" -H "$(auth)"
    echo '{"ok":true}'
    ;;

  projects)
    curl -sS -X GET "$API/projects" -H "$(auth)" | jq '.results // .'
    ;;

  project)
    project_id="${2:?project_id required}"
    curl -sS -X GET "$API/projects/$project_id" -H "$(auth)"
    ;;

  add-project)
    name="${2:?name required}"
    curl -sS -X POST "$API/projects" \
      -H "$(auth)" \
      -H "Content-Type: application/json" \
      -H "X-Request-Id: $(reqid)" \
      -d "{\"name\":$(echo "$name" | jq -R .)}"
    ;;

  labels)
    curl -sS -X GET "$API/labels" -H "$(auth)" | jq '.results // .'
    ;;

  help|*)
    cat <<EOF
Todoist CLI — REST API v1

Commands:
  tasks [filter]                List tasks (optional Todoist filter)
  filter <filter>               Alias for tasks <filter>
  task <id>                     Get single task
  add <content> [due] [proj]    Create task
  complete <id>                 Complete task
  reopen <id>                   Reopen task
  update <id> key=val...        Update task fields
  delete <id>                   Delete task
  projects                      List projects
  project <id>                  Get single project
  add-project <name>            Create project
  labels                        List labels

Token: reads from TODOIST_API_TOKEN env (e.g. ~/.hermes/.env).
EOF
    ;;
esac
