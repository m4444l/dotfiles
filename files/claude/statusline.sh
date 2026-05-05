#!/usr/bin/env bash
# Claude Code status line: model name + context window usage

input=$(cat)

model=$(echo "$input"    | jq -r '.model.display_name // "Unknown model"')
effort=$(echo "$input"   | jq -r '.effort.level // empty')
thinking=$(echo "$input" | jq -r '.thinking.enabled // empty')
used=$(echo "$input"     | jq -r '.context_window.used_percentage // empty')
rl_5h=$(echo "$input"    | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_7d=$(echo "$input"    | jq -r '.rate_limits.seven_day.used_percentage // empty')

# ANSI colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
WHITE='\033[0;37m'
RESET='\033[0m'

color_for() {
  awk -v v="$1" -v g="$GREEN" -v y="$YELLOW" -v r="$RED" \
    'BEGIN { printf (v < 50) ? g : (v < 75) ? y : r }'
}

SEP=" ${WHITE}•${RESET} "

# Build left-side plain text (model + effort + thinking) to measure width
left_plain="$model"
[ -n "$effort" ]                && left_plain+=" • effort: $effort"
[ "$thinking" = "true" ]        && left_plain+=" • thinking"

# Build right-side plain text to measure width
right_plain=""
[ -n "$used" ]  && right_plain+=$(printf "ctx: %.0f%%" "$used")
[ -n "$rl_5h" ] && right_plain+=$([ -n "$right_plain" ] && printf " • ")$(printf "5h: %.0f%%" "$rl_5h")
[ -n "$rl_7d" ] && right_plain+=$([ -n "$right_plain" ] && printf " • ")$(printf "7d: %.0f%%" "$rl_7d")

cols=${COLUMNS:-$(tput cols 2>/dev/null || echo 120)}
pad=$(( cols - ${#left_plain} - ${#right_plain} ))
[ "$pad" -lt 1 ] && pad=1

printf "${CYAN}%s${RESET}" "$model"
[ -n "$effort" ]         && printf "${SEP}${CYAN}effort: %s${RESET}" "$effort"
[ "$thinking" = "true" ] && printf "${SEP}${CYAN}thinking${RESET}"
printf "%*s" "$pad" ""
first=1
if [ -n "$used" ]; then
  printf "$(color_for "$used")ctx: %.0f%%${RESET}" "$used"; first=0
fi
if [ -n "$rl_5h" ]; then
  [ "$first" -eq 0 ] && printf "${SEP}"
  printf "$(color_for "$rl_5h")5h: %.0f%%${RESET}" "$rl_5h"; first=0
fi
if [ -n "$rl_7d" ]; then
  [ "$first" -eq 0 ] && printf "${SEP}"
  printf "$(color_for "$rl_7d")7d: %.0f%%${RESET}" "$rl_7d"
fi
