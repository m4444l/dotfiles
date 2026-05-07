#!/usr/bin/env bash
# Claude Code status line: model name + rate limit usage bars

input=$(cat)

model=$(echo "$input"    | jq -r '.model.display_name // "Unknown model"')
effort=$(echo "$input"   | jq -r '.effort.level // empty')
thinking=$(echo "$input" | jq -r '.thinking.enabled // empty')
ctx=$(echo "$input"      | jq -r '.context_window.used_percentage // empty')
rl5_used=$(echo "$input"  | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl5_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rl7_used=$(echo "$input"  | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl7_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# ANSI colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
DIM='\033[2;37m'
WHITE='\033[0;37m'
RESET='\033[0m'

color_for() {
  awk -v v="$1" -v g="$GREEN" -v y="$YELLOW" -v r="$RED" \
    'BEGIN { printf (v < 50) ? g : (v < 75) ? y : r }'
}

# Render 10 dots based on a 0-100 percentage
dots() {
  local pct="$1"
  local color filled i
  color=$(color_for "$pct")
  filled=$(awk -v v="$pct" 'BEGIN { f = int(v/10 + 0.5); if (f>10) f=10; if (f<0) f=0; printf "%d", f }')
  printf "${color}"
  for ((i=0; i<filled; i++)); do printf "● "; done
  printf "${DIM}"
  for ((i=filled; i<10; i++)); do printf "○ "; done
  printf "${RESET}"
}

# "1hr 26min" — for the 5-hour window (always < 5h away)
fmt_duration() {
  local ts="$1" now diff h m
  now=$(date +%s)
  diff=$((ts - now))
  [ $diff -lt 0 ] && diff=0
  h=$((diff / 3600))
  m=$(((diff % 3600) / 60))
  if [ $h -gt 0 ]; then
    printf "%dhr %dmin" "$h" "$m"
  else
    printf "%dmin" "$m"
  fi
}

# "Sun 10:00pm" — for the 7-day window
fmt_daytime() {
  date -r "$1" "+%a %-I:%M%p" | sed -e 's/AM$/am/' -e 's/PM$/pm/'
}

RESET_GLYPH="↻"

# Line 1: model + effort + thinking + ctx
SEP=" ${WHITE}•${RESET} "
printf "${CYAN}%s${RESET}" "$model"
[ -n "$effort" ]         && printf "${SEP}${CYAN}effort: %s${RESET}" "$effort"
[ "$thinking" = "true" ] && printf "${SEP}${CYAN}thinking${RESET}"
if [ -n "$ctx" ]; then
  printf "${SEP}$(color_for "$ctx")ctx: %.0f%%${RESET}" "$ctx"
fi
printf "\n"

# Line 2: current (5h)
if [ -n "$rl5_used" ]; then
  printf "${WHITE}current${RESET}  "
  dots "$rl5_used"
  printf " $(color_for "$rl5_used")%3.0f%%${RESET}" "$rl5_used"
  if [ -n "$rl5_reset" ]; then
    printf " ${DIM}${RESET_GLYPH} %s${RESET}" "$(fmt_duration "$rl5_reset")"
  fi
  printf "\n"
fi

# Line 3: weekly (7d)
if [ -n "$rl7_used" ]; then
  printf "${WHITE}weekly${RESET}   "
  dots "$rl7_used"
  printf " $(color_for "$rl7_used")%3.0f%%${RESET}" "$rl7_used"
  if [ -n "$rl7_reset" ]; then
    printf " ${DIM}${RESET_GLYPH} %s${RESET}" "$(fmt_daytime "$rl7_reset")"
  fi
fi
